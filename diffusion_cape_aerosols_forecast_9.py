# This version includes the intermediary three hour forecast and uses 2000 steps
# The dataset has the following order
#   - Layers 0-2 are the gfs now/forecasts for CAPE
#   - Layers 3-8 are aerosols
#   - Layer 9 is the true CAPE from gfs

from dataclasses import dataclass
from safetensors.torch import save_file, load_file
import numpy as np
import torch
from PIL import Image

print(torch.cuda.is_available())

@dataclass
class TrainingConfig:
    image_size = 128  # the generated image resolution
    train_batch_size = 16
    eval_batch_size = 16  # how many images to sample during evaluation
    num_epochs = 1000
    gradient_accumulation_steps = 1
    learning_rate = 5e-6
    lr_warmup_steps = 1000
    save_image_epochs = 100
    save_model_epochs = 200
    mixed_precision = 'fp16'  # `no` for float32, `fp16` for automatic mixed precision
    output_dir = 'cape-aerosol-gfs-summer-2000-v9'  # the model name locally and on the HF Hub

    push_to_hub = True  # whether to upload the saved model to the HF Hub
    hub_private_repo = False  
    overwrite_output_dir = True  # overwrite the old model when re-running the notebook
    seed = 0

config = TrainingConfig()

import datasets
# dataset = datasets.load_from_disk("gfs-merra-1800-2400-0-3-6-forecast-arrow-table")
dataset = datasets.load_from_disk("gefs-merra-1800-2400-0-3-6-summer-forecast-arrow-table")
max_val, min_val = 10000, 0

def transform(examples):
    
    images = []
    for image in examples["fields"]:
        # image = torch.tensor(image)[:,:64,:128]
        # image = torch.tensor(image)[:,(77-64):(77),17:145]
        image = torch.tensor(image)[:,(77-64):(77),36:164]
        cols = [0,1,2,8]
        image[cols,:,:] = (image[cols,:,:] - min_val) / (max_val - min_val)
        image[cols,:,:] = image[cols,:,:] - .5
        image[cols,:,:] = image[cols,:,:] * 2.0  # Scale to [-1, 1]
        image[cols,:,:] = torch.sqrt(image[cols,:,:]+1) # Sqrt transform
        images.append(image)
    # images = [torch.tensor(image)[5,:64,:128].unsqueeze(0) for image in examples["input"]]
    return {"fields": images}

dataset.set_transform(transform)

train_dataloader = torch.utils.data.DataLoader(dataset, batch_size=config.train_batch_size, shuffle=True)
from diffusers import UNet2DModel


model = UNet2DModel(
    sample_size=(64,128),#(76, 140),#config.image_size,  # the target image resolution
    in_channels=9,  # the number of input channels,
    out_channels=1,  # the number of output channels
    layers_per_block=2,  # how many ResNet layers to use per UNet block
    block_out_channels=(128, 128, 256, 256, 512, 512),  # the number of output channel for each UNet block
    down_block_types=( 
        "DownBlock2D",  # a regular ResNet downsampling block
        "DownBlock2D", 
        "DownBlock2D", 
        "DownBlock2D", 
        "AttnDownBlock2D",  # a ResNet downsampling block with spatial self-attention
        "DownBlock2D",
    ), 
    up_block_types=(
        "UpBlock2D",  # a regular ResNet upsampling block
        "AttnUpBlock2D",  # a ResNet upsampling block with spatial self-attention
        "UpBlock2D", 
        "UpBlock2D", 
        "UpBlock2D", 
        "UpBlock2D"  
      ),
)

# model.load_state_dict(load_file("cape-aerosol-gfs-summer-2000-v9/checkpoints/model_diffusion_cape_gfs_9.3_999.safetensors"))
model.load_state_dict(load_file("cape-aerosol-gfs-summer-2000-v9/checkpoints/model_diffusion_cape_gfs_9.3.1_399.safetensors"))
# model.load_state_dict(load_file("cape-aerosol-gfs-summer-2000-v9/temp.safetensors"))

sample_image = dataset[0]['fields'].unsqueeze(0)
print('Input shape:', sample_image.shape)
print('Output shape:', model(sample_image, timestep=0).sample.shape)

from diffusers import DDPMScheduler, DDIMScheduler

noise_scheduler = DDPMScheduler(num_train_timesteps=2000)
import torch.nn.functional as F

optimizer = torch.optim.AdamW(model.parameters(), lr=config.learning_rate)
from diffusers.optimization import get_cosine_schedule_with_warmup

lr_scheduler = get_cosine_schedule_with_warmup(
    optimizer=optimizer,
    num_warmup_steps=config.lr_warmup_steps,
    num_training_steps=(len(train_dataloader) * config.num_epochs),
)
# from diffusers import DDPMPipeline
from pipeline_ddpm_conditional import DDPMPipelineConditional
import math

def make_grid(images, rows, cols):
    w, h = 128, 64#images[0].size
    grid = Image.new('F', size=(cols*w, rows*h))
    for i, image in enumerate(images):
        print(torch.max(image), torch.min(image))
        grid.paste(Image.fromarray(np.array(image).squeeze(0)), box=(i%cols*w, i//cols*h))
        # grid.paste(Image.fromarray(np.array(dataset[i]['output'][0,:,:])), box=(i%cols*w, i//cols*h))
    return grid

def evaluate(config, epoch, pipeline):
    # Sample some images from random noise (this is the backward diffusion process).
    # The default pipeline output type is `List[PIL.Image]`
    images = pipeline(
        torch.stack(dataset[:16]['fields'])[:,:8,:,:], 
        batch_size = config.eval_batch_size, 
        generator=torch.manual_seed(config.seed),
        output_type="numpy",
        num_inference_steps=2000,
    ).images

    # Make a grid out of the images
    image_grid = make_grid(images, rows=4, cols=4)
    image_grid = image_grid.transpose(Image.FLIP_TOP_BOTTOM)
    # Save the images
    test_dir = os.path.join(config.output_dir, "samples")
    os.makedirs(test_dir, exist_ok=True)
    image_grid.save(f"{test_dir}/{epoch:04d}.tiff")
    return image_grid


from accelerate import Accelerator
from accelerate.utils import ProjectConfiguration
from huggingface_hub import create_repo, upload_folder

from tqdm.auto import tqdm
from pathlib import Path
import os

def train_loop(config, model, noise_scheduler, optimizer, train_dataloader, lr_scheduler):
    # Initialize accelerator and tensorboard logging
    logging_dir = os.path.join(config.output_dir, "logs_ft_400_2")
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
    
    global_step = 55858

    # Train the model
    for epoch in range(400, 600):#range(config.num_epochs):
        progress_bar = tqdm(total=len(train_dataloader), disable=not accelerator.is_local_main_process)
        progress_bar.set_description(f"Epoch {epoch}")

        for step, batch in enumerate(train_dataloader):
            clean_images = batch['fields'][:,8,:,:].unsqueeze(1)
            attributes = batch['fields'][:,:8,:,:]
            # Sample noise to add to the images
            noise = torch.randn(clean_images.shape).to(clean_images.device)
            bs = clean_images.shape[0]
            # Sample a random timestep for each image
            timesteps = torch.randint(0, noise_scheduler.num_train_timesteps, (bs,), device=clean_images.device).long()

            # Add noise to the clean images according to the noise magnitude at each timestep
            # (this is the forward diffusion process)
            noisy_images = noise_scheduler.add_noise(clean_images, noise, timesteps)
            drop_mask = (torch.rand(bs, device=attributes.device) < 0.1)
            drop_mask_4d = drop_mask[:, None, None, None].float()
            null_condition = torch.full_like(attributes, -10.0)
            null_condition[:,[0,3,4,5,6,7],:,:] = attributes[:,[0,3,4,5,6,7],:,:]  # just drop the gfs forecasts
            cond = attributes * (1 - drop_mask_4d) + null_condition * drop_mask_4d
            noisy_images = torch.cat((cond, noisy_images), dim=1)
            with accelerator.accumulate(model):
                # Predict the noise residual
                noise_pred = model(noisy_images, timesteps, return_dict=False)[0]
                
                # --- per-sample loss ---
                per_sample_loss = F.mse_loss(
                    noise_pred, noise, reduction="none"
                ).mean(dim=(1, 2, 3))   # [B]
                
                loss = F.mse_loss(noise_pred, noise)
                accelerator.backward(loss)

                # --- gradient norm ---
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
            # --- split conditional vs unconditional loss ---
            cond_mask   = torch.logical_not(drop_mask)
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

            logs = {
                "loss": loss.detach().item(),
                "loss/cond": cond_loss.detach().item(),
                "loss/uncond": uncond_loss.detach().item(),
                "grad_norm": grad_norm.detach().item(),
                "lr": lr_scheduler.get_last_lr()[0],
                "epoch": epoch,
            }
            progress_bar.update(1)
            # logs = {"loss": loss.detach().item(), "lr": lr_scheduler.get_last_lr()[0], "step": global_step}
            progress_bar.set_postfix(**logs)
            accelerator.log(logs, step=global_step)
            global_step += 1

        # After each epoch you optionally sample some demo images with evaluate() and save the model
        if accelerator.is_main_process:
            pipeline = DDPMPipelineConditional(unet=accelerator.unwrap_model(model), scheduler=noise_scheduler)


            if (epoch + 1) % config.save_image_epochs == 0 or epoch == config.num_epochs - 1:
                evaluate(config, epoch, pipeline)
                # fixed_conditioning = torch.stack(dataset[:16]['fields'])[:,:8,:,:]
                # with torch.no_grad():
                #     images = pipeline(
                #         fixed_conditioning,
                #         generator=torch.manual_seed(config.seed),
                #         output_type="pt",
                #         num_inference_steps=200,
                #     ).images
                # accelerator.log({"samples": images}, step=global_step,log_kwargs={"tensorboard": {"dataformats": "NCHW"}},)
            save_file(model.state_dict(), f"{config.output_dir}/temp.safetensors")
            if (epoch + 1) % config.save_model_epochs == 0 or epoch == config.num_epochs - 1:
                check_point_dir = f"{config.output_dir}/checkpoints"
                os.makedirs(check_point_dir, exist_ok=True)
                save_file(model.state_dict(), f"{config.output_dir}/checkpoints/model_diffusion_cape_gfs_9.3.1_{epoch}.safetensors")
                if config.push_to_hub:
                    upload_folder(
                        repo_id=repo_id,
                        folder_path=config.output_dir,
                        commit_message=f"Epoch {epoch}",
                        ignore_patterns=["step_*", "epoch_*"],
                    )
                else:
                    pipeline.save_pretrained(config.output_dir) 

args = (config, model, noise_scheduler, optimizer, train_dataloader, lr_scheduler)
train_loop(*args)
