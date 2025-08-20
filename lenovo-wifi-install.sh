#!/bin/bash

# Exit on error
set -e

echo "Installing required packages..."
sudo apt update
sudo apt install -y build-essential dkms git

echo "Cloning RTL8852BE driver from HRex39..."
git clone https://github.com/HRex39/rtl8852be.git
cd rtl8852be

echo "Building and installing the driver..."
make
sudo make install

echo "Loading the driver module..."
sudo modprobe 8852be

echo "Driver installed. Reboot your system to activate Wi-Fi."
