from diffusers import UNet2DModel
from safetensors.torch import load_file
import torch
import numpy as np
import pandas as pd
import rasterio
from pathlib import Path

from tqdm import tqdm

from pipeline_ddpm_conditional import DDPMPipelineConditional

model = UNet2DModel(
    sample_size=(64,128),#(76, 140),#config.image_size,  # the target image resolution
    in_channels=8,  # the number of input channels,
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

from dataclasses import dataclass

@dataclass
class TrainingConfig:
    image_size = 128  # the generated image resolution
    train_batch_size = 16
    eval_batch_size = 30#16  # how many images to sample during evaluation
    num_epochs = 20
    gradient_accumulation_steps = 1
    learning_rate = 5e-6
    lr_warmup_steps = 1000
    save_image_epochs = 5
    save_model_epochs = 20
    mixed_precision = 'fp16'  # `no` for float32, `fp16` for automatic mixed precision
    output_dir = 'cape-aerosol-gefs-summer-2000-v8'  # the model name locally and on the HF Hub

    push_to_hub = False  # whether to upload the saved model to the HF Hub
    hub_private_repo = False  
    overwrite_output_dir = False  # overwrite the old model when re-running the notebook
    seed = 10

config = TrainingConfig()
# model.load_state_dict(torch.load("/home/zj37/lightning/cape-aerosol-gfs-forecast/checkpoints/model_diffusion_cape_gfs_1.0_99.pt"))
model.load_state_dict(load_file("cape-aerosol-gefs-summer-2000-v8/checkpoints/model_diffusion_cape_gfs_8.2_599.safetensors"))

from accelerate import Accelerator
from accelerate.utils import ProjectConfiguration
from diffusers import DDPMScheduler, DDPMPipeline
from PIL import Image
import os

noise_scheduler = DDPMScheduler(num_train_timesteps=2000)

logging_dir = os.path.join(config.output_dir, "logs")
accelerator_project_config = ProjectConfiguration(project_dir=config.output_dir, logging_dir=logging_dir)
accelerator = Accelerator(
    mixed_precision=config.mixed_precision,
    gradient_accumulation_steps=config.gradient_accumulation_steps, 
    log_with="tensorboard",
    project_config=accelerator_project_config,
)

model = accelerator.prepare(model)

pipeline = DDPMPipelineConditional(unet=accelerator.unwrap_model(model), scheduler=noise_scheduler)

# import datasets
# dataset = datasets.load_from_disk("cape-aerosols-2300")

# min_val, max_val = 0, 5000
# image_index = 4929

# def transform(examples):
#     images = []
#     for image in examples["fields"]:
#         image = torch.tensor(image)[:,:64,:128]#.unsqueeze(0)
#         image[5:,:,:] = (image[5:,:,:] - min_val) / (max_val - min_val)
#         image[5:,:,:] = image[5:,:,:] - .5
#         image[5:,:,:] = image[5:,:,:] * 2.0  # Scale to [-1, 1]
#         images.append(image)
#     return {"fields": images}

# dataset.set_transform(transform)

# images = pipeline(
#     torch.tensor(dataset[image_index]['fields']).repeat(config.eval_batch_size, 1, 1, 1)[:,:6,:,:],
#     batch_size = config.eval_batch_size, 
#     generator=torch.manual_seed(config.seed),
#     output_type="numpy"
# ).images

# # Save the images
# test_dir = os.path.join(config.output_dir, "manual_samples")
# os.makedirs(test_dir, exist_ok=True)

# for i, image in enumerate(images):
#     print(np.array(image).shape)
#     Image.fromarray(np.array(image).squeeze(0)).save(f"{test_dir}/sample_20150701_{i}.tiff")

# Given a raster input let's generate outputs

def load_raster(path):
    with rasterio.open(path) as src:
        arr = src.read()  # shape: (bands, height, width)
    return arr.astype(np.float32)

min_val, max_val = 0, 10000
# input = load_raster("test-images/20150701_zero_intervention.tif")  # shape: (7, 64, 128)
# input = load_raster("scoring-combined-gefs/20250803.tif")
input = load_raster("20250803_20250401.tif")
# input = torch.tensor(input)[:,(77-64):(77),17:145]
# input = torch.tensor(input)[:,(77-64):(77),36:164]
cols = [0,6,7]
input[cols,:,:] = (input[cols,:,:] - min_val) / (max_val - min_val)
input[cols,:,:] = input[cols,:,:] - .5
input[cols,:,:] = input[cols,:,:] * 2.0  # Scale to [-1, 1]
input[cols,:,:] = np.sqrt(input[cols,:,:]+1)
input = torch.tensor(input).unsqueeze(0)

sampled_images = []
for i in range(1):#range(0, 512, config.eval_batch_size):
    print(i)
    images = pipeline(
        torch.tensor(input).repeat(config.eval_batch_size, 1, 1, 1)[:,:7,:,:],
        batch_size = config.eval_batch_size, 
        generator=torch.manual_seed(config.seed+i),
        output_type="numpy",
        num_inference_steps=2000,
        guidance_scale=0.6,
    ).images
    sampled_images += images

test_dir = os.path.join(config.output_dir, "manual_samples")
os.makedirs(test_dir, exist_ok=True)
for i, image in enumerate(sampled_images):
    img = Image.fromarray(np.array(image).squeeze(0))
    img = img.transpose(Image.FLIP_TOP_BOTTOM)
    img.save(f"{test_dir}/20250803_20250401/{i}.tiff")
    # img.save("crs/20220101/ensemble/" + str(i) + ".tif")