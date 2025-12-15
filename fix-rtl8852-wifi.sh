#!/bin/bash
set -e

echo "=== RTL8852 WiFi Fix for Ubuntu 20.04 ==="

# 1. Install HWE kernel (5.15)
echo "[1/6] Installing HWE kernel..."
apt update
apt install -y --install-recommends linux-generic-hwe-20.04-edge

# 2. Install build tools
echo "[2/6] Installing build dependencies..."
apt install -y build-essential dkms git linux-headers-$(uname -r)

# 3. Install Realtek rtw89 driver
echo "[3/6] Installing Realtek rtw89 driver..."
cd /usr/src
if [ ! -d rtw89 ]; then
  git clone https://github.com/lwfinger/rtw89.git
fi
cd rtw89
make clean || true
make
make install

# 4. Load driver
echo "[4/6] Loading WiFi driver..."
depmod -a
modprobe rtw89pci

# 5. Ensure driver loads on boot
echo "[5/6] Enabling driver at boot..."
echo "rtw89pci" > /etc/modules-load.d/rtw89.conf

# 6. Set regulatory domain (India)
echo "[6/6] Setting regulatory domain..."
iw reg set IN || true
sed -i 's/^REGDOMAIN=.*/REGDOMAIN=IN/' /etc/default/crda || true

echo "=== DONE ==="
echo "Reboot the system now."
