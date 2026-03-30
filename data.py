import torch
import datasets

def load_dataset():
    """Load the dataset from disk."""
    dataset = datasets.load_from_disk("gefs-merra-1800-2400-summer-finetune-forecast-arrow-table")
    return dataset

def create_transform():
    """Create the data transformation function."""
    max_val, min_val = 10000, 0

    def transform(examples):
        images = []
        for image in examples["fields"]:
            image = torch.tensor(image)[:, (77-64):(77), 36:164]
            cols = [0, 6, 7]
            image[cols, :, :] = (image[cols, :, :] - min_val) / (max_val - min_val)
            image[cols, :, :] = image[cols, :, :] - .5
            image[cols, :, :] = image[cols, :, :] * 2.0  # Scale to [-1, 1]
            image[cols, :, :] = torch.sqrt(image[cols, :, :] + 1)  # Sqrt transform
            images.append(image)
        return {"fields": images}

    return transform

def create_dataloader(dataset, config):
    """Create training dataloader."""
    transform = create_transform()
    dataset.set_transform(transform)
    train_dataloader = torch.utils.data.DataLoader(
        dataset,
        batch_size=config.train_batch_size,
        shuffle=True
    )
    return train_dataloader