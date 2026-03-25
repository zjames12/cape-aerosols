import torch
import torchvision
import torchvision.transforms as transforms

import numpy as np

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
print("Using device:", device)
dataset = torch.load("rasterpatch_dataset4.pt",weights_only=False)
batch_size = 64#len(dataset)
dataloader = torch.utils.data.DataLoader(dataset, batch_size=batch_size,
                                         shuffle=True, num_workers=2)

import torch.nn as nn
import torch.nn.functional as F
import random
import numpy as np
import torch

def set_seed(seed=42):
    random.seed(seed)                      # Python random
    np.random.seed(seed)                   # NumPy
    torch.manual_seed(seed)                # CPU
    torch.cuda.manual_seed(seed)           # GPU
    torch.cuda.manual_seed_all(seed)       # Multi-GPU
    torch.backends.cudnn.deterministic = True
    torch.backends.cudnn.benchmark = False





#Defining the convolutional neural network
class Net(nn.Module):
    def __init__(self):
        super().__init__()
        self.layer1 = nn.Sequential(
        nn.Conv2d(1, 6, kernel_size=5, stride=1, padding=0),
        nn.BatchNorm2d(6),
        nn.ReLU(),
        nn.MaxPool2d(kernel_size = 2, stride = 2))
        self.layer2 = nn.Sequential(
        nn.Conv2d(6, 16, kernel_size=5, stride=1, padding=0),
        nn.BatchNorm2d(16),
        nn.ReLU(),
        nn.MaxPool2d(kernel_size = 2, stride = 2))
        self.fc = nn.Linear(16*42*42, 120)
        self.relu = nn.ReLU()
        self.fc1 = nn.Linear(120, 84)
        self.relu1 = nn.ReLU()
        self.fc2 = nn.Linear(84, 1)

    def forward(self, x):
        out = self.layer1(x)
        # print(out.shape)
        out = self.layer2(out)
        # print(out.shape)
        out = out.reshape(out.size(0), -1)
        # print(out.shape)
        out = self.fc(out)
        out = self.relu(out)
        out = self.fc1(out)
        out = self.relu1(out)
        out = self.fc2(out)
        return out


net = Net().to(device)

import torch.optim as optim

set_seed()

net = Net()
criterion = nn.MSELoss()
# optimizer = optim.SGD(net.parameters(), lr=1e-5)
optimizer = optim.Adam(net.parameters(), lr=1e-5)

for epoch in range(1):  # loop over the dataset multiple times

    running_loss = 0.0
    i = 0
    for data in dataloader:
        i += 1
        # get the inputs; data is a list of [inputs, labels]
        inputs, labels = data
        inputs, labels = inputs.float(), labels.float()
        inputs = inputs.unsqueeze(1)
        # inputs = (inputs - torch.mean(inputs))/torch.std(inputs)
        # labels = (labels - torch.mean(labels))/torch.std(labels)
        labels = labels.unsqueeze(-1)
        # print(inputs.shape, labels.shape)
        # break
        # zero the parameter gradients
        optimizer.zero_grad()

        # forward + backward + optimize
        outputs = net(inputs)
        loss = criterion(outputs, labels)
        loss.backward()
        optimizer.step()

        # print statistics
        running_loss += loss.item()
        if i % 1 == 0:    # print every 2000 mini-batches
            print(f'[{epoch + 1}, {i + 1:5d}] loss: {running_loss:.3f}')
            running_loss = 0.0

print('Finished Training')
y = [y for x,y in dataset]
y = torch.tensor(y)
x = [torch.tensor(x).unsqueeze(0).unsqueeze(0) for x,y in dataset]
x = torch.cat(x)
print(f'Loss: {torch.mean(torch.square(y-net(x)))}')

PATH = './cifar_net.pth'
torch.save(net.state_dict(), PATH)