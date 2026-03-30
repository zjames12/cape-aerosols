#!/usr/bin/env python3
"""
Training script for CAPE no-aerosols diffusion model.

This script uses the unified training system to train the no-aerosols model variant.
"""

from config import get_no_aerosols_config
from no_aerosols_model import create_no_aerosols_model, load_pretrained_no_aerosols_model
from data import load_dataset, create_dataloader
from train import setup_training, setup_lr_scheduler, train_loop
from utils import check_cuda, print_model_info

def main():
    """Main training function for no-aerosols model."""
    # Check CUDA availability
    check_cuda()

    # Load configuration for no-aerosols model
    config = get_no_aerosols_config()
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
    print("Creating no-aerosols model...")
    model = create_no_aerosols_model()

    # Load pretrained weights if available
    checkpoint_path = "cape-no-aerosol-gfs-summer-2000-v8/checkpoints/model_diffusion_cape_no_aerosol_gfs_8_999.safetensors"
    try:
        model = load_pretrained_no_aerosols_model(model, checkpoint_path)
        print(f"Loaded pretrained model from {checkpoint_path}")
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