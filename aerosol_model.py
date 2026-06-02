#!/usr/bin/env python3
"""
Aerosols diffusion model definition and utilities.

This module defines the UNet2D model architecture for aerosols-conditioned
CAPE prediction and provides functions for model creation and loading.
"""

import torch
from diffusers import UNet2DModel
from safetensors.torch import load_file

def create_model():
    """Create and return the UNet2D model."""
    model = UNet2DModel(
        sample_size=(64, 128),  # the target image resolution
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
    return model

def load_pretrained_model(model, checkpoint_path):
    """Load pretrained weights into the model."""
    model.load_state_dict(load_file(checkpoint_path))
    return model