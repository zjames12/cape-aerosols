from dataclasses import dataclass
from typing import List, Optional

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
    output_dir: str = 'cape-aerosol-gefs-test'  # the model name locally and on the HF Hub

    push_to_hub = False  # whether to upload the saved model to the HF Hub
    hub_private_repo = False
    overwrite_output_dir = True  # overwrite the old model when re-running the notebook
    seed = 0

    # Model-specific parameters
    model_type: str = 'aerosols'  # 'aerosols' or 'no_aerosols'
    input_channels: List[int] = None  # Which channels to use for conditioning
    logging_suffix: str = ""  # Suffix for logging directory
    checkpoint_prefix: str = "model_diffusion_cape_gfs_10"  # Prefix for checkpoint names
    epoch_range: tuple = (0, 2)  # (start_epoch, end_epoch)
    global_step_start: int = 11905  # Starting global step
    detailed_logging: bool = False  # Whether to log detailed metrics

    def __post_init__(self):
        # Set default input channels based on model type
        if self.input_channels is None:
            if self.model_type == 'aerosols':
                self.input_channels = list(range(7))  # [0, 1, 2, 3, 4, 5, 6]
            else:  # no_aerosols
                self.input_channels = [0, 6]

# Predefined configurations
def get_aerosols_config():
    return TrainingConfig(
        model_type='aerosols',
        output_dir='cape-aerosol-gefs-summer-2000-test',
        input_channels=list(range(7)),
        logging_suffix="",
        checkpoint_prefix="model_diffusion_cape_gfs_10",
        epoch_range=(0, 1),
        global_step_start=0,
        detailed_logging=False
    )

def get_no_aerosols_config():
    return TrainingConfig(
        model_type='no_aerosols',
        output_dir='cape-no-aerosol-gfs-summer-2000-v8',
        input_channels=[0, 6],
        logging_suffix=".8.2",
        checkpoint_prefix="model_diffusion_cape_no_aerosol_gfs_8.2",
        epoch_range=(1000, 1400),
        global_step_start=0,
        detailed_logging=True
    )