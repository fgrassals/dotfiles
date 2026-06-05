#!/usr/bin/env bash
# Arch Linux install script
# Run from the live ISO as root. Connect to the internet before running.
# Edit the variables below before running.

set -euo pipefail

# =============================================================================
# CONFIGURATION
# =============================================================================
DISK="/dev/nvme0n1"
HOSTNAME="yourhostname"
USERNAME="yourusername"
TIMEZONE="Region/City"   # e.g. America/New_York

# =============================================================================
# DERIVED
# =============================================================================
PART_BOOT="${DISK}p1"
PART_LUKS="${DISK}p2"
BTRFS_OPTS="noatime,compress=zstd:1"

# =============================================================================
# PRE-FLIGHT
# =============================================================================
[[ $EUID -ne 0 ]] && echo "Run as root." && exit 1

echo "WARNING: This will wipe ${DISK} entirely."
read -rp "Type YES to continue: " confirm
[[ "$confirm" == "YES" ]] || { echo "Aborted."; exit 0; }

# =============================================================================
# CLOCK
# =============================================================================
timedatectl set-ntp true
timedatectl set-timezone "$TIMEZONE"

# =============================================================================
# PARTITION
# =============================================================================
sgdisk --zap-all "$DISK"
sgdisk -n 1:0:+1G  -t 1:EF00 "$DISK"
sgdisk -n 2:0:0    -t 2:8300 -c 2:cryptroot "$DISK"
partprobe "$DISK"

# =============================================================================
# FORMAT + LUKS
# =============================================================================
mkfs.fat -F32 "$PART_BOOT"

cryptsetup luksFormat --type luks2 "$PART_LUKS"
cryptsetup open "$PART_LUKS" cryptroot

mkfs.btrfs -L arch /dev/mapper/cryptroot

# =============================================================================
# BTRFS SUBVOLUMES
# =============================================================================
mount /dev/mapper/cryptroot /mnt

btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@var_log
btrfs subvolume create /mnt/@var_cache
btrfs subvolume create /mnt/@var_tmp
btrfs subvolume create /mnt/@var_lib_docker

umount /mnt

# =============================================================================
# MOUNT
# =============================================================================
mount -o "${BTRFS_OPTS},subvol=@" /dev/mapper/cryptroot /mnt

mkdir -p /mnt/{boot,home,var/log,var/cache,var/tmp,var/lib/docker}

mount -o "${BTRFS_OPTS},subvol=@home"           /dev/mapper/cryptroot /mnt/home
mount -o "${BTRFS_OPTS},subvol=@var_log"        /dev/mapper/cryptroot /mnt/var/log
mount -o "${BTRFS_OPTS},subvol=@var_cache"      /dev/mapper/cryptroot /mnt/var/cache
mount -o "${BTRFS_OPTS},subvol=@var_tmp"        /dev/mapper/cryptroot /mnt/var/tmp
mount -o "${BTRFS_OPTS},subvol=@var_lib_docker" /dev/mapper/cryptroot /mnt/var/lib/docker

mount "$PART_BOOT" /mnt/boot

# =============================================================================
# PACSTRAP
# =============================================================================
pacstrap -K /mnt \
    base base-devel \
    linux linux-firmware linux-headers \
    amd-ucode \
    btrfs-progs \
    grub efibootmgr \
    cryptsetup \
    networkmanager \
    sudo \
    git \
    vim nano less \
    zsh

# =============================================================================
# FSTAB
# =============================================================================
genfstab -U /mnt >> /mnt/etc/fstab

# =============================================================================
# CHROOT — SYSTEM CONFIGURATION
# =============================================================================
LUKS_UUID=$(blkid -s UUID -o value "$PART_LUKS")
export LUKS_UUID TIMEZONE HOSTNAME USERNAME

arch-chroot /mnt /bin/bash <<'EOF'
set -euo pipefail

ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
hwclock --systohc

sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

echo "${HOSTNAME}" > /etc/hostname

sed -i 's/^MODULES=.*/MODULES=(btrfs)/' /etc/mkinitcpio.conf
sed -i 's/^HOOKS=.*/HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt filesystems fsck)/' /etc/mkinitcpio.conf
mkinitcpio -P

useradd -m -G wheel -s /bin/zsh "$USERNAME"
echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel

systemctl enable NetworkManager

sed -i "s|^GRUB_CMDLINE_LINUX=.*|GRUB_CMDLINE_LINUX=\"rd.luks.name=${LUKS_UUID}=cryptroot root=/dev/mapper/cryptroot\"|" /etc/default/grub
sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="mem_sleep_default=s2idle /' /etc/default/grub
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=grub
grub-mkconfig -o /boot/grub/grub.cfg
EOF

echo "Set root password:"
arch-chroot /mnt passwd
echo "Set password for ${USERNAME}:"
arch-chroot /mnt passwd "$USERNAME"

# =============================================================================
# DONE
# =============================================================================
umount -R /mnt
cryptsetup close cryptroot

echo ""
echo "Installation complete. Remove the USB and reboot."
