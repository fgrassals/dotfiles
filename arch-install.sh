#!/usr/bin/env bash
# Run from the Arch ISO as root with network access after editing the variables.

set -euo pipefail

# =============================================================================
# CONFIGURATION
# =============================================================================
DISK=""
HOSTNAME="yourhostname"
USERNAME="yourusername"
TIMEZONE="Region/City"   # e.g. America/New_York

# =============================================================================
# PRE-FLIGHT
# =============================================================================
[[ $EUID -ne 0 ]] && echo "Run as root." && exit 1
[[ -d /sys/firmware/efi/efivars ]] || { echo "Boot the Arch ISO in UEFI mode." >&2; exit 1; }
for tool in lsblk mountpoint sgdisk partprobe mkfs.fat cryptsetup mkfs.ext4 pacstrap genfstab arch-chroot udevadm; do
    command -v "$tool" >/dev/null || { echo "Missing live-ISO tool: $tool" >&2; exit 1; }
done
[[ -n "$DISK" && -b "$DISK" ]] || { echo "Set DISK to an existing block device." >&2; exit 1; }
[[ $(lsblk -dn -o TYPE "$DISK") == disk ]] || { echo "DISK must be a whole disk." >&2; exit 1; }
[[ -n "$HOSTNAME" && -n "$USERNAME" && -n "$TIMEZONE" && "$HOSTNAME" != yourhostname && "$USERNAME" != yourusername && "$TIMEZONE" != Region/City ]] || {
    echo "Set HOSTNAME, USERNAME, and TIMEZONE before running." >&2; exit 1;
}
[[ -f "/usr/share/zoneinfo/$TIMEZONE" ]] || { echo "Invalid TIMEZONE: $TIMEZONE" >&2; exit 1; }

DISK=$(readlink -f "$DISK")
if lsblk -nr -o MOUNTPOINT "$DISK" | grep -q '[^[:space:]]'; then
    echo "Unmount all partitions on $DISK before installing." >&2
    exit 1
fi
if mountpoint -q /mnt; then
    echo "Unmount /mnt before installing." >&2
    exit 1
fi
if [[ "$DISK" == *[0-9] ]]; then
    PART_BOOT="${DISK}p1"
    PART_LUKS="${DISK}p2"
else
    PART_BOOT="${DISK}1"
    PART_LUKS="${DISK}2"
fi

echo "WARNING: This will wipe ${DISK} entirely."
read -rp "Type ${DISK} to continue: " confirm
[[ "$confirm" == "$DISK" ]] || { echo "Aborted."; exit 0; }

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
udevadm settle

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
    mkinitcpio plymouth dosfstools \
    networkmanager \
    zram-generator \
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
sed -i 's/^HOOKS=.*/HOOKS=(base systemd plymouth keyboard autodetect microcode modconf kms sd-vconsole block sd-encrypt filesystems fsck)/' /etc/mkinitcpio.conf

plymouth-set-default-theme spinfinity
mkinitcpio -P

useradd -m -G wheel -s /bin/zsh "$USERNAME"
echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel
chmod 0440 /etc/sudoers.d/wheel

systemctl enable NetworkManager

cat > /etc/systemd/zram-generator.conf <<ZRAM
[zram0]
zram-size = min(ram / 2, 8192)
compression-algorithm = zstd
ZRAM

bootctl install

cat > /boot/loader/loader.conf <<LOADER
default  arch.conf
timeout  3
console-mode keep
editor   yes
LOADER

CMDLINE="rd.luks.name=${LUKS_UUID}=cryptroot rd.luks.options=discard root=/dev/mapper/cryptroot rw mem_sleep_default=s2idle quiet splash loglevel=3"

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
echo "If using Wi-Fi, connect with nmcli before running arch-post-install.sh."
