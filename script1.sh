#!/bin/bash

# Ensure script is being run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "Please run this script as root."
  exit 1
fi

# Update system and install necessary tools
sudo xbps-install -Syu
sudo xbps-install -y git curl btrfs-progs gparted

# Partition the drive with Btrfs setup
echo "Setting up Btrfs partitioning..."
# You may customize partition sizes and layout as needed
# Example: Partitioning /dev/sda
parted /dev/sda mklabel gpt
parted /dev/sda mkpart ESP fat32 1MiB 512MiB
parted /dev/sda set 1 boot on
parted /dev/sda mkpart primary btrfs 512MiB 100%
mkfs.fat -F32 /dev/sda1
mkfs.btrfs /dev/sda2

# Mount and create subvolumes
mount /dev/sda2 /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@var
btrfs subvolume create /mnt/@snapshots
umount /mnt

# Mount subvolumes
mount -o subvol=@ /dev/sda2 /mnt
mkdir -p /mnt/{boot,home,var,snapshots}
mount -o subvol=@home /dev/sda2 /mnt/home
mount -o subvol=@var /dev/sda2 /mnt/var
mount -o subvol=@snapshots /dev/sda2 /mnt/snapshots
mount /dev/sda1 /mnt/boot

echo "Btrfs partitioning and subvolumes setup complete."

# Prompt user to run Calamares installer
echo "Please proceed with the Calamares installer to complete the Void Linux installation."
echo "After the installation, run script2.sh to complete the setup."

# Clone the Voidcraft repository and Script 2 from GitHub (placeholders)
echo "Cloning Voidcraft and Script 2 from GitHub..."
git clone https://github.com/ChickenParmigiana/craft-repo
cd craft-repo
chmod +x script2.sh

# Final message
echo "Script 1 completed. Run script2.sh after completing the Void Linux installation with Calamares."
