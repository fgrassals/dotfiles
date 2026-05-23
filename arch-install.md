# Arch Linux Installation Guide

Hardware: Ryzen AI 350 (Strix Point), 64GB RAM, NVMe SSD, UEFI

---

## Phase 1 — Boot the ISO

Verify UEFI mode:
```bash
ls /sys/firmware/efi/efivars
```

Sync the clock and set your timezone:
```bash
timedatectl set-ntp true
timedatectl set-timezone Region/City   # e.g. America/New_York
```

Connect to WiFi if needed:
```bash
iwctl
  station wlan0 scan
  station wlan0 connect "SSID"
  exit
ping archlinux.org
```

---

## Phase 2 — Partition

Find your disk:
```bash
lsblk
```

```bash
gdisk /dev/nvme0n1
```

- `o` — new GPT partition table
- `n` → partition 1 → `+1G` → type `EF00` (EFI System — unencrypted `/boot`)
- `n` → partition 2 → default (rest of disk) → type `8300` (Linux filesystem — LUKS)
- `w` — write and exit

---

## Phase 3 — Format + LUKS

```bash
mkfs.fat -F32 /dev/nvme0n1p1
```

```bash
cryptsetup luksFormat --type luks2 /dev/nvme0n1p2
cryptsetup open /dev/nvme0n1p2 cryptroot
```

```bash
mkfs.btrfs -L arch /dev/mapper/cryptroot
```

---

## Phase 4 — Btrfs subvolumes

```bash
mount /dev/mapper/cryptroot /mnt

btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@var_log
btrfs subvolume create /mnt/@var_cache
btrfs subvolume create /mnt/@var_tmp
btrfs subvolume create /mnt/@var_lib_docker

umount /mnt
```

Snapper snapshots `@` only. The other subvolumes are excluded:

| Subvolume | Mount | Snapshotted |
|---|---|---|
| `@` | `/` | ✅ — includes `/usr`, `/etc` |
| `@home` | `/home` | ❌ |
| `@snapshots` | `/.snapshots` | ❌ — snapper stores snapshots here |
| `@var_log` | `/var/log` | ❌ |
| `@var_cache` | `/var/cache` | ❌ |
| `@var_tmp` | `/var/tmp` | ❌ |
| `@var_lib_docker` | `/var/lib/docker` | ❌ |

`/boot` is the ESP (FAT32, `nvme0n1p1`) — outside the Btrfs tree and unencrypted. GRUB reads the kernel and initramfs from there without decrypting anything. The `sd-encrypt` hook in the initramfs asks for the passphrase once to unlock the root volume. `snap-pac` (installed by the post-install script) creates pre/post snapshots automatically on every pacman operation. `grub-btrfs` adds snapshot entries to the GRUB menu so you can boot into them.

---

## Phase 5 — Mount

```bash
BTRFS_OPTS="noatime,compress=zstd:1"

mount -o ${BTRFS_OPTS},subvol=@ /dev/mapper/cryptroot /mnt

mkdir -p /mnt/{boot,home,.snapshots,var/log,var/cache,var/tmp,var/lib/docker}

mount -o ${BTRFS_OPTS},subvol=@home           /dev/mapper/cryptroot /mnt/home
mount -o ${BTRFS_OPTS},subvol=@snapshots      /dev/mapper/cryptroot /mnt/.snapshots
mount -o ${BTRFS_OPTS},subvol=@var_log        /dev/mapper/cryptroot /mnt/var/log
mount -o ${BTRFS_OPTS},subvol=@var_cache      /dev/mapper/cryptroot /mnt/var/cache
mount -o ${BTRFS_OPTS},subvol=@var_tmp        /dev/mapper/cryptroot /mnt/var/tmp
mount -o ${BTRFS_OPTS},subvol=@var_lib_docker /dev/mapper/cryptroot /mnt/var/lib/docker

mount /dev/nvme0n1p1 /mnt/boot
```

---

## Phase 6 — pacstrap

```bash
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
    neovim \
    zsh
```

`linux-firmware` is not included in `base` — required for GPU, WiFi, and other hardware.  
`amd-ucode` — CPU microcode, packed into the initramfs by the `microcode` hook in mkinitcpio.  
`btrfs-progs` — required for the initramfs to mount the root subvolume.

---

## Phase 7 — fstab

```bash
genfstab -U /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab   # verify all 8 mount points are present
```

---

## Phase 8 — chroot

```bash
arch-chroot /mnt
```

---

## Phase 9 — System configuration

**Timezone:**
```bash
ln -sf /usr/share/zoneinfo/Region/City /etc/localtime
hwclock --systohc
```

**Locale:**
```bash
nvim /etc/locale.gen        # uncomment en_US.UTF-8
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
```

**Hostname:**
```bash
echo "yourhostname" > /etc/hostname
```

**initramfs** — add `btrfs` to MODULES and `sd-encrypt` to HOOKS (before `filesystems`):
```bash
nvim /etc/mkinitcpio.conf
# MODULES=(btrfs)
# HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt filesystems fsck)
mkinitcpio -P
```

**Root password:**
```bash
passwd
```

**User:**
```bash
useradd -m -G wheel -s /bin/zsh yourusername
passwd yourusername
```

**sudo:**
```bash
EDITOR=nvim visudo
# uncomment: %wheel ALL=(ALL:ALL) ALL
```

**NetworkManager:**
```bash
systemctl enable NetworkManager
```

**GRUB:**
```bash
blkid -s UUID -o value /dev/nvme0n1p2
```

```bash
nvim /etc/default/grub
# Add to GRUB_CMDLINE_LINUX: rd.luks.name=<uuid>=cryptroot root=/dev/mapper/cryptroot
```

```bash
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=grub
grub-mkconfig -o /boot/grub/grub.cfg
```

---

## Phase 10 — Reboot

```bash
exit
umount -R /mnt
reboot
```

Remove the USB. Log in as your user, clone dotfiles, run `arch-post-install.sh`.
