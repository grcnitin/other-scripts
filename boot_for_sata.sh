#!/bin/bash

rm temp.txt
touch temp.txt
RED='\033[0;31m'
Green='\033[0;32m'
NC='\033[0m'

udef_setdns()
{
    ping -c 1 google.com
    if [ $? -ne 2 ]
    then
        echo "nameserver properly configured"
    else
        echo "nameserver not configured"
        echo "nameserver 8.8.8.8" >> /etc/resolv.conf
        ping -c 1 google.com
        if [ $? -eq 0 ]
        then
            echo "nameserver configured"
        else
            echo "can't configure nameserver" >> temp.txt
        fi
    fi
}

BOOT_DISK=/dev/sda

ip a
yes '' | sed 3q
echo "Enter interface management interface name"
read mgmtint

yes '' | sed 3q
echo "Enter HOSTNAME"
read hostname
HOST_NAME=$hostname
echo Hostname is $HOST_NAME

yes '' | sed 3q
echo "Enter TIMEZONE"
read timezone
TIME_ZONE=$timezone
echo Timezone is $TIME_ZONE

ROOT_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC0Fjw9qyijwpsGAyWIpBI1Bjjy2fKeOrr9bGMnGNVhcZWFvsWMvgRfmVh5TLyZ/qVOb6xfyca/hBYmUqTgKvclLmZWyXkwodHRtXsjwKB/vCSHacOnKwtfvkYdMyJbrDAa8Sx7NpzvJE8im6bjtkGCDd20yvmsxQRvP/nGvovCrpIsrIjsvrlyhfWadYlvL+98Rywvmb6om9w713VWVBXYbNWshvODFFcPJ5AvvnxORt91UGMprF/wUtzQgVuUzIinvZcTWvYeYTJX0UuqbWPqVCx/pq9ZDSxTnp2WPe6ApfmClkhIIppQN7GSwT5JJeX4iFnciq/EQWDXMVe+xa3mVE9M+MTBGb/o+SuIAyYmBgCfSQkkRgn24nIEpihlZkrsKP4AkKPf6MjJoOZxmO7WLjgbmZYAW4P6B5NNL3en0XtWLRBRlUew44S/I3VovrZE2gGbe91q129f51ah+j1ynJDsGxIFlaf93XsZgS6lmK7TEEcS/qSd16Ny073YgArMMgICsp0+IqUiETRwdTcdajQdVIMNaFYMx2FexkWryCEiJ/ZJx0TC3lF3lirx5KtY4Qee2PufrArN3XEJ7MOVA31d2vD/t/mTKbJTVSaxWn/aPGlNiYKWssGMxWmkP1GU7bUJmyvwP76CyYeKHADpMxdWrbRFunggbWCRgmH5zw== rituka.sharma@gravitontrading.com"

sed -i "s/Required DatabaseOptional/Never/g" /etc/pacman.conf
sed -i "s/Required DatabaseOptional/Never/g" /mnt/etc/pacman.conf
cat /etc/pacman.conf | grep DisableDownloadTimeout
if [ $? -ne 0 ] ;  then
sed -i  '/^# Misc options/a DisableDownloadTimeout' /etc/pacman.conf
fi

DATA_DISK1=/dev/sda
#DATA_DISK2=/dev/sdb

RAID_DISK=/dev/md0

echo 'Server = http://archive.archlinux.org/repos/2022/11/10/$repo/os/$arch' > /etc/pacman.d/mirrorlist
#echo 'Server = http://archive.archlinux.org/repos/2023/01/01/$repo/os/$arch' > /etc/pacman.d/mirrorlist


ls /sys/firmware/efi/efivars > /dev/null
udef_setdns
timedatectl | grep -q 'clock synchronized: yes' || date -s "$(curl -sD - google.com | grep ^Date: | cut -d' ' -f3-6)Z"
hwclock --systohc --utc

parted -s "${BOOT_DISK}" mklabel gpt
parted -s "${BOOT_DISK}" mkpart ESP fat32 1MiB 513MiB
parted -s "${BOOT_DISK}" set 1 boot on
parted -s "${BOOT_DISK}" mkpart primary ext4 513MiB 100%
partprobe "${BOOT_DISK}"

mkfs.fat -F32 "${BOOT_DISK}1"
dosfslabel "${BOOT_DISK}1" "EFISYS"
mkfs.ext4 "${BOOT_DISK}2"
mount "${BOOT_DISK}2" /mnt
mkdir -p /mnt/boot
mount "${BOOT_DISK}1" /mnt/boot
pacstrap /mnt base base-devel
#mdadm --create --verbose --level=1 --metadata=1.2 --chunk=64 --raid-devices=2 "${RAID_DISK}" "${DATA_DISK1}" "${DATA_DISK2}"
#mkfs.ext4 "${RAID_DISK}"
#e2label "${RAID_DISK}" "data"

#mkdir -p /mnt/mnt/data
#ln -s /mnt/data /mnt/data
#mount "${RAID_DISK}" /mnt/mnt/data

ln -s /usr/share/zoneinfo/"${TIME_ZONE}" /mnt/etc/localtime
sed -i '/^#en_US.UTF-8/s/^#//' /mnt/etc/locale.gen
arch-chroot /mnt locale-gen
echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
echo "${HOST_NAME}" > /mnt/etc/hostname

genfstab -U /mnt > /mnt/etc/fstab

arch-chroot /mnt pacman --noconfirm --asdeps -S git jshon

arch-chroot /mnt git clone https://github.com/oshazard/apacman.git /root/apacman

arch-chroot /mnt pacman -S bc cronie dbus-glib efibootmgr htop i7z linux linux-headers linux-lts linux-lts-headers tmux vim multitail netctl man nano gdb lsof mutt openssh perf pkgfile powerline python-configobj python-msgpack rlwrap wget
arch-chroot /mnt pacman -S python-psutil python-pyinotify python-setproctitle python-tornado r rsync  socat

arch-chroot /mnt pacman -S python-pandas s3cmd

arch-chroot /mnt bootctl install

mkdir -p /mnt/boot/EFI/systemd
mkdir -p /mnt/boot/EFI/Boot

cp /mnt/usr/lib/systemd/boot/efi/systemd-bootx64.efi /mnt/boot/EFI/systemd/
cp /mnt/usr/lib/systemd/boot/efi/systemd-bootx64.efi /mnt/boot/EFI/Boot/BOOTX64.EFI

arch-chroot /mnt efibootmgr -c -d "${BOOT_DISK}" -p 1 -l /EFI/systemd/systemd-bootx64.efi -L "Linux Boot Manager"
mkdir -p /mnt/boot/loader/entries

cat << EOF > /mnt/boot/loader/entries/linux-lts.conf
title          Arch Linux LTS
linux          /vmlinuz-linux-lts
initrd         /initramfs-linux-lts.img
options        root=PARTUUID=$(cd /dev/disk/by-partuuid/; for v in *; do if [ $(readlink -f $v) == "${BOOT_DISK}2" ]; then echo $v;
fi; done) rw  intel_idle.max_cstate=0 idle=poll
EOF

cat << EOF > /mnt/boot/loader/loader.conf
default linux-lts
timeout 5
EOF

arch-chroot /mnt useradd -g users -s /bin/bash -m -o -u 1000 trading
#arch-chroot /mnt chown trading:users /mnt/data

cat << EOF > /mnt/etc/security/limits.conf
@users soft core unlimited
EOF

cat << EOF > /mnt/etc/sudoers.d/trading
trading ALL=(ALL) NOPASSWD: ALL
EOF

cat << EOF > /mnt/etc/sudoers.d/proxy
Defaults env_keep += "http_proxy"
Defaults env_keep += "https_proxy"
Defaults env_keep += "ftp_proxy"
EOF


mkdir /mnt/etc/netctl
Address=$(ip add show $mgmtint | grep inet | head -1 | awk {'print $2'})
Gateway=$(ip route show default | awk {'print $3'})
cat << EOF > /mnt/etc/netctl/mgmt
Description='management link'
Interface=$mgmtint
Connection=ethernet
SkipNoCarrier=yes
IP=static
Address=('$Address')
Gateway='$Gateway'
DNS=('8.8.8.8')
EOF

echo -e "${RED} Please verify netctl output below before reboot ${NC}" >> temp.txt
cat /mnt/etc/netctl/mgmt >> temp.txt

arch-chroot /mnt netctl enable mgmt
mkdir -p /mnt/root/.ssh
echo "${ROOT_KEY}" > /mnt/root/.ssh/authorized_keys

mkdir -p /mnt/home/trading/.ssh
arch-chroot /mnt sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
echo "${ROOT_KEY}" > /mnt/home/trading/.ssh/authorized_keys
arch-chroot /mnt echo root:123456 | chpasswd
arch-chroot /mnt systemctl enable sshd.service
arch-chroot /mnt systemctl enable cronie.service

yes '' | sed 5q
cat temp.txt
