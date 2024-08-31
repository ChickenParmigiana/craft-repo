#!/bin/bash

# Variables (adjust these as necessary)
DRIVE="/dev/nvme0n1"     # Main drive
BOOT_PARTITION="${DRIVE}p1"
ROOT_PARTITION="${DRIVE}p2"
EFI_SIZE="512M"

# Step 1: Partition the drive
echo "Partitioning the drive..."
parted --script $DRIVE mklabel gpt
parted --script $DRIVE mkpart primary fat32 1MiB $EFI_SIZE
parted --script $DRIVE set 1 esp on
parted --script $DRIVE mkpart primary btrfs $EFI_SIZE 100%

# Step 2: Format the partitions
echo "Formatting the partitions..."
mkfs.vfat -F32 $BOOT_PARTITION
mkfs.btrfs -f $ROOT_PARTITION

# Step 3: Create Btrfs subvolumes
echo "Creating Btrfs subvolumes..."
mount $ROOT_PARTITION /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@var_log
btrfs subvolume create /mnt/@var_tmp
btrfs subvolume create /mnt/@var_cache
btrfs subvolume create /mnt/@snapshots
umount /mnt

# Step 4: Mount the subvolumes
echo "Mounting the subvolumes..."
mount -o subvol=@ $ROOT_PARTITION /mnt
mkdir -p /mnt/{home,var/log,var/tmp,var/cache,snapshots,boot}
mount -o subvol=@home $ROOT_PARTITION /mnt/home
mount -o subvol=@var_log $ROOT_PARTITION /mnt/var/log
mount -o subvol=@var_tmp $ROOT_PARTITION /mnt/var/tmp
mount -o subvol=@var_cache $ROOT_PARTITION /mnt/var/cache
mount -o subvol=@snapshots $ROOT_PARTITION /mnt/snapshots
mount $BOOT_PARTITION /mnt/boot

# Step 5: Configure ZRAM with ZSTD Compression
echo "Configuring ZRAM with ZSTD compression..."
sudo xbps-install -y zramctl
echo 'zram0' > /etc/modules-load.d/zram.conf
echo 'options zram num_devices=1' > /etc/modprobe.d/zram.conf
echo 'KERNEL=="zram0", ATTR{comp_algorithm}="zstd", ATTR{disksize}="16G", RUN="/usr/sbin/mkswap /dev/zram0", TAG+="systemd"' > /etc/udev/rules.d/99-zram.rules
echo "/dev/zram0 none swap defaults 0 0" >> /etc/fstab
swapon /dev/zram0

echo "Partitioning and ZRAM setup complete. You can now run the Calamares installer."

