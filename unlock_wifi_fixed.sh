#!/bin/bash

set -e

echo "Reverting Wi-Fi lockdown..."

# Remove the blacklist file
blacklist_file="/etc/modprobe.d/blacklist-wifi.conf"
if [ -f "$blacklist_file" ]; then
    echo "Removing Wi-Fi module blacklist..."
    sudo rm "$blacklist_file"
fi

# Remove the NetworkManager config that ignores the Wi-Fi interface
nm_conf_file="/etc/NetworkManager/conf.d/no-wifi.conf"
if [ -f "$nm_conf_file" ]; then
    echo "Removing NetworkManager Wi-Fi ignore config..."
    sudo rm "$nm_conf_file"
    echo "Restarting NetworkManager..."
    sudo systemctl restart NetworkManager
fi

# Remove the Polkit rule requiring admin for Wi-Fi toggle
polkit_rule_file="/etc/polkit-1/rules.d/10-disable-wifi.rules"
if [ -f "$polkit_rule_file" ]; then
    echo "Removing Polkit rule for Wi-Fi toggle..."
    sudo rm "$polkit_rule_file"
fi

# Update initramfs
echo "Updating initramfs..."
sudo update-initramfs -u

echo "Wi-Fi lockdown has been reverted. Please reboot the system."
