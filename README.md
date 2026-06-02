# Improving Ensemble CAPE Forecasts with a Diffusion Model Incorporating Aerosol Information

## Overview

This repository contains code for training and evaluating diffusion models that generate ensemble CAPE forecasts given a deterministic forecast. The DMs are image-to-image, conditioned on the current atmsopheric state. We present two types of models:
- **Aerosols model**: Uses CAPE fields and aerosol data as input (7 channels)
- **CAPE-only model**: Uses only CAPE fields (2 channels)

The project compares AI-generated ensemble forecasts against operational GEFS (Global Ensemble Forecast System) predictions.

## Project Structure

```
├── README.md                    # This file
├── config.py                   # Training configuration and model parameters
├── data.py                     # Dataset loading and preprocessing
├── main_train.py               # Main training script for aerosols model
├── train_unified.py            # Unified training script for both model types
├── train.py                    # Core training loop and utilities
├── train_no_aerosols.py        # Training script for no-aerosols model
├── aerosol_model.py            # Aerosols model definition
├── no_aerosols_model.py        # No-aerosols model definition
├── utils.py                    # Utility functions
├── pipeline_ddpm_conditional.py # DDPM conditional pipeline
├── sampler_scoring.py          # Sampling and scoring utilities
├── metrics/                    # Evaluation metrics
│   ├── rmse.py                # RMSE and spread-skill analysis
│   ├── crps.py                # CRPS (Continuous Ranked Probability Score)
│   └── brier.py               # Brier score evaluation
└── analysis/                   # Analysis and visualization scripts
```

## Models

### Aerosols Model
- **Input**: 7 channels (5 aerosol + 2 CAPE)
- **Output**: 1 channel (CAPE prediction)
- **Architecture**: UNet2D with attention blocks
- **Resolution**: 64×128 pixels

### No-Aerosols Model
- **Input**: 2 channels (2 CAPE variables)
- **Output**: 1 channel (CAPE prediction)
- **Architecture**: Similar UNet2D architecture

## Usage

### Training

Train the aerosols model:
```bash
python main_train.py
```

Train using the unified script:
```bash
python train_unified.py aerosols     # Train aerosols model
python train_unified.py no_aerosols  # Train no-aerosols model
```

### Configuration

Model and training parameters can be configured in `config.py`:
- Batch size, learning rate, number of epochs
- Model architecture parameters
- Input/output directories
- Logging settings

### Evaluation

The `metrics/` directory contains scripts for evaluating model performance:
- **RMSE analysis**: `metrics/rmse.py`
- **CRPS evaluation**: `metrics/crps.py`
- **Brier score**: `metrics/brier.py`

## Dependencies

- PyTorch
- Diffusers (Hugging Face)
- xarray
- rioxarray
- pandas
- numpy
- safetensors
- datasets (Hugging Face)
- tqdm

## Data

The training data can be found on [HuggingFace](https://huggingface.co/datasets/zj37/gfs-merra-1800-2400-forecast)

## Model Weights

The aerosol model weights can be found [here](https://huggingface.co/zj37/cape-aerosol-gfs-summer-2000-v8), and the CAPE-Only model weights can be found [here](https://huggingface.co/zj37/cape-no-aerosol-gfs-summer-2000-v8)