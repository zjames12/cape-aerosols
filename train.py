import os
import torch
import torch.nn.functional as F
from pathlib import Path
from tqdm.auto import tqdm

from accelerate import Accelerator
from accelerate.utils import ProjectConfiguration
from huggingface_hub import create_repo, upload_folder
from diffusers import DDPMScheduler
from diffusers.optimization import get_cosine_schedule_with_warmup
from safetensors.torch import save_file

from pipeline_ddpm_conditional import DDPMPipelineConditional
from utils import evaluate

def setup_training(config, model):
    """Setup optimizer, scheduler, and other training components."""
    noise_scheduler = DDPMScheduler(num_train_timesteps=2000)

    optimizer = torch.optim.AdamW(model.parameters(), lr=config.learning_rate)

    return noise_scheduler, optimizer

def setup_lr_scheduler(config, optimizer, train_dataloader):
    """Setup learning rate scheduler."""
    lr_scheduler = get_cosine_schedule_with_warmup(
        optimizer=optimizer,
        num_warmup_steps=config.lr_warmup_steps,
        num_training_steps=(len(train_dataloader) * config.num_epochs),
    )
    return lr_scheduler

def train_loop(config, model, noise_scheduler, optimizer, train_dataloader, lr_scheduler, dataset):
    """Main training loop with support for both aerosol and no-aerosol models."""
    # Initialize accelerator and tensorboard logging
    logging_dir = os.path.join(config.output_dir, f"logs{config.logging_suffix}")
    accelerator_project_config = ProjectConfiguration(project_dir=config.output_dir, logging_dir=logging_dir)
    accelerator = Accelerator(
        mixed_precision=config.mixed_precision,
        gradient_accumulation_steps=config.gradient_accumulation_steps,
        log_with="tensorboard",
        project_config=accelerator_project_config,
    )

    if accelerator.is_main_process:
        if config.push_to_hub:
            repo_id = create_repo(
                repo_id=Path(config.output_dir).name, exist_ok=True
            ).repo_id
        elif config.output_dir is not None:
            os.makedirs(config.output_dir, exist_ok=True)
        accelerator.init_trackers("train_example")

    # Prepare everything
    model, optimizer, train_dataloader, lr_scheduler = accelerator.prepare(
        model, optimizer, train_dataloader, lr_scheduler
    )

    global_step = config.global_step_start

    # Train the model
    start_epoch, end_epoch = config.epoch_range
    for epoch in range(start_epoch, end_epoch):
        progress_bar = tqdm(total=len(train_dataloader), disable=not accelerator.is_local_main_process)
        progress_bar.set_description(f"Epoch {epoch}")

        for step, batch in enumerate(train_dataloader):
            clean_images = batch['fields'][:, 7, :, :].unsqueeze(1)
            # Use config-specified input channels
            attributes = batch['fields'][:, config.input_channels, :, :]

            # Sample noise to add to the images
            noise = torch.randn(clean_images.shape).to(clean_images.device)
            bs = clean_images.shape[0]

            # Sample a random timestep for each image
            timesteps = torch.randint(
                0, noise_scheduler.num_train_timesteps, (bs,), device=clean_images.device
            ).long()

            # Add noise to the clean images according to the noise magnitude at each timestep
            noisy_images = noise_scheduler.add_noise(clean_images, noise, timesteps)

            # Classifier-free guidance dropout
            drop_mask = (torch.rand(bs, device=attributes.device) < 0.1)
            drop_mask_4d = drop_mask[:, None, None, None].float()
            null_condition = torch.full_like(attributes, -10.0)

            # Handle different null condition strategies
            if config.model_type == 'aerosols':
                null_condition[:, 1:7, :, :] = attributes[:, 1:7, :, :]  # just drop the gfs forecast
            else:  # no_aerosols
                null_condition[:, 1, :, :] = attributes[:, 1, :, :]  # just drop the gfs forecast

            cond = attributes * (1 - drop_mask_4d) + null_condition * drop_mask_4d
            noisy_images = torch.cat((cond, noisy_images), dim=1)

            with accelerator.accumulate(model):
                # Predict the noise residual
                noise_pred = model(noisy_images, timesteps, return_dict=False)[0]

                # Calculate per-sample loss for detailed logging if enabled
                if config.detailed_logging:
                    per_sample_loss = F.mse_loss(
                        noise_pred, noise, reduction="none"
                    ).mean(dim=(1, 2, 3))  # [B]

                loss = F.mse_loss(noise_pred, noise)
                accelerator.backward(loss)

                # Calculate gradient norm if detailed logging is enabled
                if config.detailed_logging:
                    grad_norm = torch.norm(
                        torch.stack([
                            p.grad.detach().norm(2)
                            for p in model.parameters()
                            if p.grad is not None
                        ]),
                        2
                    )

                accelerator.clip_grad_norm_(model.parameters(), 1.0)
                optimizer.step()
                lr_scheduler.step()
                optimizer.zero_grad()

            # Prepare logging
            logs = {"loss": loss.detach().item(), "lr": lr_scheduler.get_last_lr()[0]}

            # Add detailed logging if enabled
            if config.detailed_logging:
                # Split conditional vs unconditional loss
                cond_mask = torch.logical_not(drop_mask)
                uncond_mask = drop_mask

                cond_loss = (
                    per_sample_loss[cond_mask].mean()
                    if cond_mask.any()
                    else torch.tensor(0.0, device=loss.device)
                )

                uncond_loss = (
                    per_sample_loss[uncond_mask].mean()
                    if uncond_mask.any()
                    else torch.tensor(0.0, device=loss.device)
                )

                logs.update({
                    "loss/cond": cond_loss.detach().item(),
                    "loss/uncond": uncond_loss.detach().item(),
                    "grad_norm": grad_norm.detach().item(),
                })

            progress_bar.update(1)
            progress_bar.set_postfix(**logs)
            accelerator.log(logs, step=global_step)
            global_step += 1

        # After each epoch you optionally sample some demo images with evaluate() and save the model
        if accelerator.is_main_process:
            pipeline = DDPMPipelineConditional(unet=accelerator.unwrap_model(model), scheduler=noise_scheduler)

            if (epoch + 1) % config.save_image_epochs == 0 or epoch == config.num_epochs - 1:
                evaluate(config, epoch, pipeline, dataset)

            save_file(model.state_dict(), f"{config.output_dir}/temp.safetensors")

            if (epoch + 1) % config.save_model_epochs == 0 or epoch == config.num_epochs - 1:
                checkpoint_name = f"{config.output_dir}/checkpoints/{config.checkpoint_prefix}_{epoch}.safetensors"
                save_file(model.state_dict(), checkpoint_name)

                if config.push_to_hub:
                    upload_folder(
                        repo_id=repo_id,
                        folder_path=config.output_dir,
                        commit_message=f"Epoch {epoch}",
                        ignore_patterns=["step_*", "epoch_*"],
                    )
                else:
                    pipeline.save_pretrained(config.output_dir)

    print(f"Training completed. Final global step: {global_step}")