#!/bin/bash

# Ensure running as root
if [ "$EUID" -ne 0 ]; then
  echo "❌ This script must be run as root"
  exit 1
fi

# Step 1: Set root password
echo "🔐 Setting root password to 'P@ssw0rd@0101'..."
echo "root:P@ssw0rd@0101" | chpasswd

# Step 2: Update /etc/pam.d/gdm-password
echo "🔧 Modifying /etc/pam.d/gdm-password..."
sed -i 's/^auth\s\+required\s\+pam_succeed_if.so user != root quiet_success/#&/' /etc/pam.d/gdm-password

# Step 3: Rename user (auto-detect old username)
OLD_USERNAME=$(ls /home | grep -Ev '^root$' | head -n 1)
echo "👤 Detected OLD username: $OLD_USERNAME"
read -p "👤 Enter NEW username (e.g., nitin.singh): " NEW_USERNAME

OLD_HOME="/home/$OLD_USERNAME"
NEW_HOME="/home/$NEW_USERNAME"

# Rename home directory
if [ -d "$OLD_HOME" ]; then
  echo "📂 Renaming home directory from $OLD_HOME to $NEW_HOME..."
  mv "$OLD_HOME" "$NEW_HOME"
  chmod 700 "$NEW_HOME"
else
  echo "❌ Home directory $OLD_HOME does not exist."
  exit 1
fi

# Update /etc/passwd completely (username, comment, home path, shell)
echo "📝 Updating /etc/passwd..."
OLD_PASSWD_LINE=$(grep "^$OLD_USERNAME:" /etc/passwd)
if [ -z "$OLD_PASSWD_LINE" ]; then
  echo "❌ Failed to find user $OLD_USERNAME in /etc/passwd."
  exit 1
fi

IFS=':' read -r _user _pw _uid _gid _comment _home _shell <<< "$OLD_PASSWD_LINE"
NEW_PASSWD_LINE="$NEW_USERNAME:$_pw:$_uid:$_gid:$NEW_USERNAME,,,:$NEW_HOME:$_shell"
sed -i "s|^$OLD_USERNAME:.*|$NEW_PASSWD_LINE|" /etc/passwd

# Update /etc/shadow
echo "📝 Updating /etc/shadow..."
sed -i "s/^$OLD_USERNAME:/$NEW_USERNAME:/" /etc/shadow

# Change ownership
echo "👤 Changing ownership of new home directory..."
chown -R "$NEW_USERNAME:users" "$NEW_HOME"

# Step 4: Install OpenSSH server
echo "📦 Installing openssh-server..."
apt-get update -y
apt-get install -y openssh-server

# Step 5: Update sshd_config
echo "🔧 Updating SSH config to allow root login..."
sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config

# Step 6: Restart SSH service
echo "🔁 Restarting SSH service..."
systemctl restart sshd

# Step 7: Disable system sleep
echo "😴 Disabling sleep..."
systemctl mask sleep.target

echo "✅ Script completed. User '$OLD_USERNAME' has been renamed to '$NEW_USERNAME'. Root SSH login is now enabled."
