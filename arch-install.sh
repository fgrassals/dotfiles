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

mkfs.ext4 -L arch /dev/mapper/cryptroot

# =============================================================================
# MOUNT
# =============================================================================
mount /dev/mapper/cryptroot /mnt
mkdir -p /mnt/boot
mount "$PART_BOOT" /mnt/boot

# =============================================================================
# PACSTRAP
# =============================================================================
pacstrap -K /mnt \
    base base-devel \
    linux linux-headers \
    linux-lts linux-lts-headers \
    linux-firmware \
    amd-ucode \
    cryptsetup \
    plymouth \
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

sed -i 's/^MODULES=.*/MODULES=()/' /etc/mkinitcpio.conf
sed -i 's/^HOOKS=.*/HOOKS=(base systemd plymouth autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt filesystems fsck)/' /etc/mkinitcpio.conf

plymouth-set-default-theme spinner
mkinitcpio -P

useradd -m -G wheel -s /bin/zsh "$USERNAME"
echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel

systemctl enable NetworkManager

# --- systemd-boot ---
bootctl install

cat > /boot/loader/loader.conf <<LOADER
default  arch.conf
timeout  3
console-mode keep
editor   yes
LOADER

CMDLINE="rd.luks.name=${LUKS_UUID}=cryptroot root=/dev/mapper/cryptroot rw mem_sleep_default=s2idle quiet splash loglevel=3"

cat > /boot/loader/entries/arch.conf <<ENTRY
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options ${CMDLINE}
ENTRY

cat > /boot/loader/entries/arch-fallback.conf <<ENTRY
title   Arch Linux (fallback initramfs)
linux   /vmlinuz-linux
initrd  /initramfs-linux-fallback.img
options ${CMDLINE}
ENTRY

cat > /boot/loader/entries/arch-lts.conf <<ENTRY
title   Arch Linux (linux-lts)
linux   /vmlinuz-linux-lts
initrd  /initramfs-linux-lts.img
options ${CMDLINE}
ENTRY

cat > /boot/loader/entries/arch-lts-fallback.conf <<ENTRY
title   Arch Linux (linux-lts, fallback initramfs)
linux   /vmlinuz-linux-lts
initrd  /initramfs-linux-lts-fallback.img
options ${CMDLINE}
ENTRY

systemctl enable systemd-boot-update.service
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
