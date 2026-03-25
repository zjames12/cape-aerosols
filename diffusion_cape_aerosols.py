from dataclasses import dataclass
import numpy as np

@dataclass
class TrainingConfig:
    image_size = 128  # the generated image resolution
    train_batch_size = 32
    eval_batch_size = 16  # how many images to sample during evaluation
    num_epochs = 20
    gradient_accumulation_steps = 1
    learning_rate = 5e-6
    lr_warmup_steps = 1000
    save_image_epochs = 5
    save_model_epochs = 5
    mixed_precision = 'fp16'  # `no` for float32, `fp16` for automatic mixed precision
    output_dir = 'ddpm-cape-aerosol-128'  # the model name locally and on the HF Hub

    push_to_hub = True  # whether to upload the saved model to the HF Hub
    hub_private_repo = False  
    overwrite_output_dir = True  # overwrite the old model when re-running the notebook
    seed = 0

config = TrainingConfig()
import datasets
dataset = datasets.load_from_disk("cape-1700-dataset")

max_val = 4000#max([np.max(np.array(arr)[5,:,:]) for arr in dataset["input"][0:100]])
min_val = 0#min([np.min(np.array(arr)[5,:,:]) for arr in dataset["input"][0:100]])
print(max_val, min_val)

def transform(examples):
    # print(torch.tensor(examples["output"][0]).shape)
    # images = [torch.tensor(image)[:,:64,:128] for image in examples["output"]]
    
    images = []
    for image in examples["input"]:
        image = torch.tensor(image)[:,:64,:128]#.unsqueeze(0)
        image[5,:,:] = (image[5,:,:] - min_val) / (max_val - min_val)  # Normalize to [-1, 1]
        image[5,:,:] = image[5,:,:] - 0.5
        images.append(image)
    # images = [torch.tensor(image)[5,:64,:128].unsqueeze(0) for image in examples["input"]]
    return {"output": images}

dataset.set_transform(transform)
import torch
from PIL import Image

train_dataloader = torch.utils.data.DataLoader(dataset, batch_size=config.train_batch_size, shuffle=True)
from diffusers import UNet2DModel


model = UNet2DModel(
    sample_size=(64,128),#(76, 140),#config.image_size,  # the target image resolution
    in_channels=7,  # the number of input channels, 3 for RGB images
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
# model.load_state_dict(torch.load("ddpm-cape-aerosol-128/checkpoints/model_diffusion_cape_119.pt"))
# model.load_state_dict(torch.load("ddpm-cape-aerosol-128/checkpoints/model_diffusion_cape_3.6_9.pt"))
sample_image = dataset[0]['output'].unsqueeze(0)
print('Input shape:', sample_image.shape)
print('Output shape:', model(sample_image, timestep=0).sample.shape)

from diffusers import DDPMScheduler

noise_scheduler = DDPMScheduler(num_train_timesteps=1000)
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
        torch.stack(dataset[:16]['output'])[:,:5,:,:], 
        batch_size = config.eval_batch_size, 
        generator=torch.manual_seed(config.seed),
        output_type="numpy"
    ).images

    # Make a grid out of the images
    image_grid = make_grid(images, rows=4, cols=4)

    # Save the images
    test_dir = os.path.join(config.output_dir, "samples")
    os.makedirs(test_dir, exist_ok=True)
    image_grid.save(f"{test_dir}/{epoch:04d}.tiff")

from accelerate import Accelerator
from accelerate.utils import ProjectConfiguration
from huggingface_hub import create_repo, upload_folder

from tqdm.auto import tqdm
from pathlib import Path
import os

def train_loop(config, model, noise_scheduler, optimizer, train_dataloader, lr_scheduler):
    # Initialize accelerator and tensorboard logging
    logging_dir = os.path.join(config.output_dir, "logs")
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
    # There is no specific order to remember, you just need to unpack the 
    # objects in the same order you gave them to the prepare method.
    model, optimizer, train_dataloader, lr_scheduler = accelerator.prepare(
        model, optimizer, train_dataloader, lr_scheduler
    )
    
    global_step = 0

    # Now you train the model
    for epoch in range(10,30):#range(config.num_epochs):
        progress_bar = tqdm(total=len(train_dataloader), disable=not accelerator.is_local_main_process)
        progress_bar.set_description(f"Epoch {epoch}")

        for step, batch in enumerate(train_dataloader):
            clean_images = batch['output'][:,5,:,:].unsqueeze(1)
            attributes = batch['output'][:,:5,:,:]
            # Sample noise to add to the images
            noise = torch.randn(clean_images.shape).to(clean_images.device)
            bs = clean_images.shape[0]
            # Sample a random timestep for each image
            timesteps = torch.randint(0, noise_scheduler.num_train_timesteps, (bs,), device=clean_images.device).long()

            # Add noise to the clean images according to the noise magnitude at each timestep
            # (this is the forward diffusion process)
            noisy_images = noise_scheduler.add_noise(clean_images, noise, timesteps)
            noisy_images = torch.cat((attributes, noisy_images), dim=1)
            with accelerator.accumulate(model):
                # Predict the noise residual
                noise_pred = model(noisy_images, timesteps, return_dict=False)[0]
                loss = F.mse_loss(noise_pred, noise)
                accelerator.backward(loss)

                accelerator.clip_grad_norm_(model.parameters(), 1.0)
                optimizer.step()
                lr_scheduler.step()
                optimizer.zero_grad()
            
            progress_bar.update(1)
            logs = {"loss": loss.detach().item(), "lr": lr_scheduler.get_last_lr()[0], "step": global_step}
            progress_bar.set_postfix(**logs)
            accelerator.log(logs, step=global_step)
            global_step += 1

        # After each epoch you optionally sample some demo images with evaluate() and save the model
        if accelerator.is_main_process:
            # pipeline = DDPMPipeline(unet=accelerator.unwrap_model(model), scheduler=noise_scheduler)
            pipeline = DDPMPipelineConditional(unet=accelerator.unwrap_model(model), scheduler=noise_scheduler)


            if (epoch + 1) % config.save_image_epochs == 0 or epoch == config.num_epochs - 1:
                evaluate(config, epoch, pipeline)

            if (epoch + 1) % config.save_model_epochs == 0 or epoch == config.num_epochs - 1:
                torch.save(model.state_dict(), f"{config.output_dir}/checkpoints/model_diffusion_cape_3.6_{epoch}.pt")
                # model.save_pretrained(output_dir)
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
# torch.save(model.state_dict(), "model_diffusion_cape_100.pt")
