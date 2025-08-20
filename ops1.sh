#!/bin/bash

curl --version
if [ $? -ne 0 ]; then
	apt-get -y install curl > /dev/null
	curl --version
fi
echo ""

wget --version
if [ $? -ne 0 ]; then
        apt-get -y install wget > /dev/null
	wget --version
fi
echo ""

R --version
if [ $? -ne 0 ]; then
        apt-get -y install r-base-core > /dev/null
	R --version
fi
echo ""

pip --version
if [ $? -ne 0 ]; then
        apt-get -y install python3-pip > /dev/null
	pip --version
fi
echo ""

ls -l /usr/bin/python
ln -s /usr/bin/python3.8 /usr/bin/python

# libcurl (reqd for R tseries later)
apt-get install libcurl4-openssl-dev > /dev/null

# libcairo
apt -y install libgirepository1.0-dev > /dev/null
#apt-get install -y texlive-full > /dev/null
apt-get install -y sox ffmpeg libcairo2 libcairo2-dev libjpeg-dev libgif-dev > /dev/null
apt-get install -y git jshon > /dev/null
apt-get -y install socat s3cmd awscli > /dev/null
apt-get -y install gobject-introspection > /dev/null
apt-get -y install libgirepository1.0-de > /dev/null

apt-get install -y zsh > /dev/null
apt-get install -y tree > /dev/null
apt-get install -y mutt > /dev/null
apt-get install -y htop > /dev/null
apt-get install -y autossh > /dev/null
apt-get install -y kcachegrind > /dev/null
apt-get install -y speedtest-cli > /dev/null
apt-get install -y tigervnc-viewer > /dev/null

apt-get -y install wget gpg > /dev/null
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
rm -v packages.microsoft.gpg

apt-get -y install apt-transport-https > /dev/null
apt-get -y update > /dev/null
apt-get -y install code > /dev/null


pip install cffi > /dev/null
apt-get -y install vim tmux > /dev/null

echo ""

#slack and telegram
snap install telegram-desktop
snap install slack --classic

#google-chrome
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
dpkg -i google-chrome-stable_current_amd64.deb
echo "google-chrome-stable --version"

#wireshark
echo "wireshark-common wireshark-common/install-setuid boolean true" | debconf-set-selections
DEBIAN_FRONTEND=noninteractive apt-get -y install wireshark

#terminator
apt-get -y install terminator

#jupyter-notebook
apt-get -y install jupyter-notebook
