#!/usr/bin/env python3
"""
Unified training script for CAPE diffusion models.

This script can train either aerosols or no-aerosols models based on command line arguments.

Usage:
    python train_unified.py aerosols    # Train aerosols model
    python train_unified.py no_aerosols # Train no-aerosols model
"""

import sys
from config import get_aerosols_config, get_no_aerosols_config
from aerosol_model import create_model, load_pretrained_model
from no_aerosols_model import create_no_aerosols_model, load_pretrained_no_aerosols_model
from data import load_dataset, create_dataloader
from train import setup_training, setup_lr_scheduler, train_loop
from utils import check_cuda, print_model_info

def main():
    """Main training function that supports both model types."""
    if len(sys.argv) != 2 or sys.argv[1] not in ['aerosols', 'no_aerosols']:
        print("Usage: python train_unified.py [aerosols|no_aerosols]")
        sys.exit(1)

    model_type = sys.argv[1]

    # Check CUDA availability
    check_cuda()

    # Load appropriate configuration
    if model_type == 'aerosols':
        config = get_aerosols_config()
        create_model_fn = create_model
        load_model_fn = load_pretrained_model
        default_checkpoint = "cape-aerosol-gefs-summer-2000-v10-no-base/temp.safetensors"
    else:  # no_aerosols
        config = get_no_aerosols_config()
        create_model_fn = create_no_aerosols_model
        load_model_fn = load_pretrained_no_aerosols_model
        default_checkpoint = "cape-no-aerosol-gfs-summer-2000-v8/checkpoints/model_diffusion_cape_no_aerosol_gfs_8_999.safetensors"

    print(f"Training {config.model_type} model")
    print(f"Input channels: {config.input_channels}")
    print(f"Output directory: {config.output_dir}")

    # Load dataset
    print("Loading dataset...")
    dataset = load_dataset()

    # Create data loader
    print("Setting up data loader...")
    train_dataloader = create_dataloader(dataset, config)

    # Create model
    print(f"Creating {config.model_type} model...")
    model = create_model_fn()

    # Load pretrained weights if available
    try:
        model = load_model_fn(model, default_checkpoint)
        print(f"Loaded pretrained model from {default_checkpoint}")
    except FileNotFoundError:
        print("No pretrained model found, starting from scratch")

    # Print model information
    print_model_info(model, dataset, config)

    # Setup training components
    print("Setting up training components...")
    noise_scheduler, optimizer = setup_training(config, model)
    lr_scheduler = setup_lr_scheduler(config, optimizer, train_dataloader)

    # Start training
    print("Starting training...")
    train_loop(config, model, noise_scheduler, optimizer, train_dataloader, lr_scheduler, dataset)

    print("Training completed!")

if __name__ == "__main__":
    main()