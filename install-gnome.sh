#!/bin/bash

# Ensure we're running as root
if [[ $EUID -ne 0 ]]; then
   echo "Please run as root or use sudo"
   exit 1
fi

echo "🔄 Updating system..."
pacman -Syu --noconfirm

echo "🖥️ Installing X.Org display server..."
pacman -S --noconfirm xorg

echo "🧩 Installing minimal GNOME components..."
pacman -S --noconfirm \
  gnome-shell \
  gnome-control-center \
  gnome-terminal \
  gdm \
  nautilus \
  gnome-settings-daemon \
  gnome-session \
  mutter \
  xdg-user-dirs

echo "✅ Enabling GDM (GNOME Display Manager)..."
systemctl enable --now gdm.service

echo "🧰 Installing VMware Tools..."
pacman -S --noconfirm open-vm-tools open-vm-tools-desktop

echo "✅ Enabling VMware Tools service..."
systemctl enable --now vmtoolsd.service

# Optional: Add 2GB swap (recommended if RAM < 2 GB)
echo "🧠 Creating optional 2GB swap file..."
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab

echo "🎉 Minimal GNOME + VMware Tools setup complete!"
echo "🔁 Rebooting in 5 seconds..."
sleep 5
reboot
