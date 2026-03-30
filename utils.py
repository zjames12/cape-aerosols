import os
import numpy as np
import torch
from PIL import Image
from pipeline_ddpm_conditional import DDPMPipelineConditional

def make_grid(images, rows, cols):
    """Create a grid of images for visualization."""
    w, h = 128, 64
    grid = Image.new('F', size=(cols*w, rows*h))
    for i, image in enumerate(images):
        print(torch.max(image), torch.min(image))
        grid.paste(Image.fromarray(np.array(image).squeeze(0)), box=(i%cols*w, i//cols*h))
    return grid

def evaluate(config, epoch, pipeline, dataset):
    """Evaluate the model by generating samples."""
    # Sample some images from random noise (this is the backward diffusion process).
    # The default pipeline output type is `List[PIL.Image]`
    # Use config.input_channels to select appropriate channels
    input_data = torch.stack(dataset[:16]['fields'])[:, config.input_channels, :, :]

    images = pipeline(
        input_data,
        batch_size=config.eval_batch_size,
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

def print_model_info(model, dataset, config=None):
    """Print model and data shape information."""
    sample_image = dataset[0]['fields'].unsqueeze(0)
    if config is not None:
        # Use the appropriate input channels for the model
        if config.model_type == 'no_aerosols':
            sample_image = sample_image[:, [0,6,7], :, :]  # Include target channel for testing
        # For aerosols model, use full input
    print('Input shape:', sample_image.shape)
    print('Output shape:', model(sample_image, timestep=0).sample.shape)

def check_cuda():
    """Check CUDA availability."""
    print(f"CUDA available: {torch.cuda.is_available()}")
    return torch.cuda.is_available()