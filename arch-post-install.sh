#!/usr/bin/env bash
# Run as your normal user after the first boot.

set -euo pipefail

# =============================================================================
# HELPERS
# =============================================================================
c_blue=$'\e[1;34m'; c_yellow=$'\e[1;33m'; c_red=$'\e[1;31m'; c_reset=$'\e[0m'
msg()  { printf '%s==>%s %s\n'  "$c_blue"   "$c_reset" "$*"; }
warn() { printf '%s::%s  %s\n' "$c_yellow" "$c_reset" "$*"; }
die()  { printf '%serror:%s %s\n' "$c_red"  "$c_reset" "$*" >&2; exit 1; }

pac() { sudo pacman -S --needed --noconfirm "$@"; }
aur() { paru -S --needed "$@"; }

# =============================================================================
# PRE-FLIGHT
# =============================================================================
[[ $EUID -eq 0 ]] && die "Run as your normal user, not root."
command -v sudo >/dev/null || die "sudo not found."

sudo -v
while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done &

# =============================================================================
# FOUNDATION — PACMAN, PARU, CLI TOOLS
# =============================================================================
foundation() {
    msg "foundation"

    sudo sed -i -e 's/^#Color/Color/' -e 's/^#ParallelDownloads.*/ParallelDownloads = 10/' /etc/pacman.conf
    grep -q '^ILoveCandy' /etc/pacman.conf || sudo sed -i '/^ParallelDownloads/a ILoveCandy' /etc/pacman.conf

    sudo pacman -Syu --noconfirm reflector
    sudo reflector --country US,CA --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist || warn "reflector failed; keeping current mirrors"
    sudo pacman -Syu --noconfirm

    pac git base-devel openssh man-db curl wl-clipboard eza fzf ripgrep fd mise stow bat starship git-delta jq yq glow zip unzip 7zip unrar tree-sitter-cli neovim pacman-contrib btop libnotify

    if ! paru -V >/dev/null 2>&1; then
        msg "bootstrapping paru"
        pacman -Q paru-bin >/dev/null 2>&1 && sudo pacman -R --noconfirm paru-bin
        tmp=$(mktemp -d)
        git clone --depth=1 https://aur.archlinux.org/paru.git "$tmp/paru"
        ( cd "$tmp/paru" && makepkg -si --noconfirm )
        rm -rf "$tmp"
    fi
}

# =============================================================================
# SYSTEM — FIREWALL, POWER, USB FILESYSTEMS
# =============================================================================
system() {
    msg "system"
    pac fwupd ufw libsecret power-profiles-daemon lm_sensors upower xdg-user-dirs xdg-utils exfatprogs

    sudo systemctl enable --now fwupd-refresh.timer

    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw --force enable
    sudo systemctl enable ufw.service

    sudo systemctl enable --now power-profiles-daemon.service

    sudo systemctl enable --now fstrim.timer

    xdg-user-dirs-update
}

# =============================================================================
# AUDIO — PIPEWIRE, BLUETOOTH
# =============================================================================
audio() {
    msg "audio"
    pac pipewire wireplumber pipewire-pulse pipewire-alsa
    systemctl --user enable --now pipewire.socket pipewire-pulse.socket wireplumber.service

    pac bluez bluez-utils
    sudo systemctl enable --now bluetooth.service
}

# =============================================================================
# KDE PLASMA
# =============================================================================
desktop() {
    msg "KDE Plasma"
    pac plasma-meta dolphin ark kamera gwenview okular haruna elisa ffmpegthumbs kdegraphics-thumbnailers qt5-wayland
}

# =============================================================================
# TERMINAL + FONTS
# =============================================================================
terminal() {
    msg "terminal"
    pac kitty konsole ttf-cascadia-mono-nerd ttf-nerd-fonts-symbols-mono

    pac noto-fonts-emoji noto-fonts-cjk

    pac ttf-liberation gsfonts ttf-carlito ttf-caladea
}

# =============================================================================
# SESSION — FINGERPRINT
# =============================================================================
session() {
    msg "session"
    pac fprintd
}

# =============================================================================
# MEDIA — CODECS, HARDWARE DECODE
# =============================================================================
media() {
    msg "media"
    pac ffmpeg gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly gst-libav libva libva-utils
}

# =============================================================================
# APPS — BROWSERS, 1PASSWORD, DOCKER
# =============================================================================
apps() {
    msg "apps"
    pac firefox chromium superfile lazygit lazydocker docker docker-compose docker-buildx
    aur 1password 1password-cli

    sudo systemctl enable --now docker.socket
    sudo usermod -aG docker "$(id -un)"
}

# =============================================================================
# LOGIN
# =============================================================================
login() {
    msg "login"
    sudo systemctl enable plasmalogin.service
}

# =============================================================================
# DOTFILES
# =============================================================================
dotfiles() {
    msg "dotfiles"
    cd "$(dirname "$(readlink -f "$0")")"
    stow -R --no-folding -t "$HOME" kitty chromium lazygit btop bat superfile starship xdg bin zsh git mise nvim systemd plasma
    mkdir -p "$HOME/Pictures/Screenshots"

    systemctl --user daemon-reload
    systemctl --user enable --now updates-check.timer

    mise install
    command -v bat >/dev/null && bat cache --build
}

# =============================================================================
# RUN
# =============================================================================
foundation
system
audio
desktop
terminal
session
media
apps
login
dotfiles
