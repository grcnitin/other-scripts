#!/bin/bash

set -e

echo "Starting fixed Wi-Fi lockdown..."

# Detect Wi-Fi kernel driver
echo "Detecting Wi-Fi kernel module..."
wifi_module=$(lspci -k | grep -A 3 -i network | grep 'Kernel driver in use' | awk -F: '{print $2}' | xargs)
if [ -z "$wifi_module" ]; then
    echo "Failed to detect Wi-Fi driver. Exiting."
    exit 1
fi
echo "Detected Wi-Fi driver: $wifi_module"

# Blacklist the Wi-Fi module
blacklist_file="/etc/modprobe.d/blacklist-wifi.conf"
echo "Blacklisting Wi-Fi module: $wifi_module"
echo "blacklist $wifi_module" | sudo tee "$blacklist_file"
echo "install $wifi_module /bin/false" | sudo tee -a "$blacklist_file"

# Update initramfs
echo "Updating initramfs..."
sudo update-initramfs -u

# Get Wi-Fi interface name safely
wifi_iface=$(iw dev | awk '$1=="Interface"{print $2}')
if [ -z "$wifi_iface" ]; then
    echo "Wi-Fi interface not found via iw dev. Skipping NetworkManager config."
else
    echo "Detected Wi-Fi interface: $wifi_iface"

    # Configure NetworkManager to ignore only the Wi-Fi interface
    nm_conf_file="/etc/NetworkManager/conf.d/no-wifi.conf"
    echo "Creating NetworkManager config to ignore Wi-Fi interface..."
    sudo mkdir -p /etc/NetworkManager/conf.d
    echo -e "[keyfile]\nunmanaged-devices=interface-name:$wifi_iface" | sudo tee "$nm_conf_file"

    echo "Restarting NetworkManager..."
    sudo systemctl restart NetworkManager
fi

# Add Polkit rule to require admin for enabling/disabling Wi-Fi
polkit_rule_file="/etc/polkit-1/rules.d/10-disable-wifi.rules"
echo "Adding Polkit rule to require root for Wi-Fi toggle"
sudo bash -c "cat > $polkit_rule_file" <<EOF
polkit.addRule(function(action, subject) {
    if (
        action.id == "org.freedesktop.NetworkManager.enable-disable-wifi"
        && !subject.isInGroup("sudo")
    ) {
        return polkit.Result.AUTH_ADMIN;
    }
});
EOF

echo "Wi-Fi lockdown complete. Please reboot to finalize all changes."
