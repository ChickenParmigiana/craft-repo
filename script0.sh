#!/bin/bash

# Set up partitions on /dev/nvme0n1

# Create partition table
parted /dev/nvme0n1 -- mklabel gpt

# Create boot partition (2GB, ext4)
parted /dev/nvme0n1 -- mkpart primary ext4 1MiB 2GiB
mkfs.ext4 -L boot /dev/nvme0n1p1

# Create main partition for Btrfs (remaining space)
parted /dev/nvme0n1 -- mkpart primary btrfs 2GiB 100%
mkfs.btrfs -L void_btrfs /dev/nvme0n1p2

# Mount the main partition
mount /dev/nvme0n1p2 /mnt

# Create Btrfs subvolumes
btrfs su cr /mnt/@
btrfs su cr /mnt/@home
btrfs su cr /mnt/@var_log
btrfs su cr /mnt/@var_tmp
btrfs su cr /mnt/@var_cache
btrfs su cr /mnt/@snapshots

# Unmount the main partition
umount /mnt

# Mount the subvolumes with the proper mount points for Calamares
mount -o subvol=@ /dev/nvme0n1p2 /mnt
mkdir -p /mnt/{boot,home,var/log,var/tmp,var/cache,snapshots}
mount /dev/nvme0n1p1 /mnt/boot
mount -o subvol=@home /dev/nvme0n1p2 /mnt/home
mount -o subvol=@var_log /dev/nvme0n1p2 /mnt/var/log
mount -o subvol=@var_tmp /dev/nvme0n1p2 /mnt/var/tmp
mount -o subvol=@var_cache /dev/nvme0n1p2 /mnt/var/cache
mount -o subvol=@snapshots /dev/nvme0n1p2 /mnt/snapshots

# Install necessary utilities
echo "Installing necessary utilities..."
sudo xbps-install -Sy btrfs-progs zramctl util-linux

# ZRAM setup with ZSTD compression
echo "Configuring ZRAM with ZSTD compression..."
modprobe zram
echo zstd > /sys/block/zram0/comp_algorithm
echo 16G > /sys/block/zram0/disksize
mkswap /dev/zram0
swapon /dev/zram0

# Check if the necessary configuration files are in place
if [ ! -f /etc/udev/rules.d/99-zram.rules ]; then
    echo "Creating ZRAM udev rule..."
    echo 'KERNEL=="zram0", ATTR{comp_algorithm}="zstd", ATTR{disksize}="16G", RUN="/sbin/mkswap /dev/zram0", TAG+="systemd"' > /etc/udev/rules.d/99-zram.rules
fi

# Finishing message
echo "Partitioning, utility installation, and ZRAM setup complete. You can now run the Calamares installer."