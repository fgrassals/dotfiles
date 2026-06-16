#!/usr/bin/env bash
# Arch post-install — niri Wayland desktop. Run as your normal user after first
# boot. Idempotent: safe to re-run. Comment out sections you're not ready for.

set -euo pipefail

# =============================================================================
# HELPERS
# =============================================================================
c_blue=$'\e[1;34m'; c_yellow=$'\e[1;33m'; c_red=$'\e[1;31m'; c_reset=$'\e[0m'
msg()  { printf '%s==>%s %s\n'  "$c_blue"   "$c_reset" "$*"; }
warn() { printf '%s::%s  %s\n'  "$c_yellow" "$c_reset" "$*"; }
die()  { printf '%serror:%s %s\n' "$c_red"  "$c_reset" "$*" >&2; exit 1; }

pac() { sudo pacman -S --needed --noconfirm "$@"; }
aur() { paru -S --needed "$@"; }

# =============================================================================
# PRE-FLIGHT
# =============================================================================
[[ $EUID -eq 0 ]] && die "Run as your normal user, not root."
command -v sudo >/dev/null || die "sudo not found."

sudo -v
# keep sudo warm for the whole run
while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done &

# =============================================================================
# FOUNDATION — pacman, paru (1Password only), core CLI/dev tools
# =============================================================================
foundation() {
    msg "foundation"

    # pacman QoL
    sudo sed -i -e 's/^#Color/Color/' -e 's/^#ParallelDownloads.*/ParallelDownloads = 10/' /etc/pacman.conf
    grep -q '^ILoveCandy' /etc/pacman.conf || sudo sed -i '/^ParallelDownloads/a ILoveCandy' /etc/pacman.conf

    # rank mirrors
    pac reflector
    sudo reflector --country US,CA --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist || warn "reflector failed; keeping mirrors"

    sudo pacman -Syu --noconfirm

    pac git base-devel openssh man-db wl-clipboard eza fzf ripgrep fd mise stow bat git-delta jq yq glow unzip 7zip unrar tree-sitter-cli neovim

    # paru
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
# SYSTEM — firewall, keyring, power management, sensors, xdg dirs
# =============================================================================
system() {
    msg "system"
    pac fwupd ufw gnome-keyring libsecret seahorse power-profiles-daemon lm_sensors upower xdg-user-dirs xdg-utils

    # low-battery notifier
    install -Dm644 /dev/stdin "$HOME/.config/systemd/user/battery-alert.service" <<'EOF'
[Unit]
Description=Low battery notifier

[Service]
ExecStart=%h/.local/bin/battery-alert
Restart=on-failure

[Install]
WantedBy=default.target
EOF
    systemctl --user enable battery-alert.service

    # firewall: deny incoming, allow outgoing
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw --force enable
    sudo systemctl enable ufw.service

    # power profiles (amd-pstate EPP)
    sudo systemctl enable power-profiles-daemon.service

    # charge-threshold helper (NOPASSWD)
    sudo install -Dm755 /dev/stdin /usr/local/bin/set-charge-threshold <<'EOF'
#!/usr/bin/env bash
# set ThinkPad charge start/stop thresholds: set-charge-threshold <80|100>
end="${1:-80}"
[[ "$end" == "100" ]] && start=95 || start=$(( end - 30 ))
for bat in /sys/class/power_supply/BAT*; do
    [[ -w "$bat/charge_control_start_threshold" ]] && echo "$start" > "$bat/charge_control_start_threshold"
    [[ -w "$bat/charge_control_end_threshold" ]]   && echo "$end"   > "$bat/charge_control_end_threshold"
done
EOF
    echo '%wheel ALL=(root) NOPASSWD: /usr/local/bin/set-charge-threshold' | sudo tee /etc/sudoers.d/charge-threshold >/dev/null
    sudo chmod 0440 /etc/sudoers.d/charge-threshold

    # apply 80% cap at boot and after resume
    sudo install -Dm644 /dev/stdin /etc/systemd/system/charge-threshold.service <<'EOF'
[Unit]
Description=Battery charge threshold 80%
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/set-charge-threshold 80

[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl enable charge-threshold.service
    sudo install -Dm755 /dev/stdin /usr/lib/systemd/system-sleep/charge-threshold <<'EOF'
#!/bin/sh
[ "$1" = post ] && /usr/local/bin/set-charge-threshold 80
exit 0
EOF

    xdg-user-dirs-update
}

# =============================================================================
# AUDIO — pipewire stack, mixer, bluetooth
# =============================================================================
audio() {
    msg "audio"
    pac pipewire wireplumber pipewire-pulse pipewire-alsa wiremix
    systemctl --user enable pipewire.socket pipewire-pulse.socket wireplumber.service

    pac bluez bluez-utils bluetui
    sudo systemctl enable bluetooth.service
}

# =============================================================================
# NIRI — compositor, xwayland, portals, polkit agent
# =============================================================================
niri() {
    msg "niri"
    pac niri xwayland-satellite xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-gnome mate-polkit
}

# =============================================================================
# TERMINAL — kitty + fonts
# =============================================================================
terminal() {
    msg "terminal"
    pac kitty ttf-cascadia-mono-nerd inter-font noto-fonts noto-fonts-emoji ttf-nerd-fonts-symbols-mono
}

# =============================================================================
# SHELL — waybar + launcher + notifications
# =============================================================================
shell() {
    msg "shell"
    pac waybar fuzzel mako btop rocm-smi-lib wlsunset swayosd libnotify
}

# =============================================================================
# SESSION — lock, idle, wallpaper, clipboard, brightness, fingerprint
# =============================================================================
session() {
    msg "session"
    pac swaylock imagemagick swayidle swaybg cliphist wl-clip-persist brightnessctl fprintd

    # lid-aware: skip fprintd when lid closed
    sudo install -Dm755 /dev/stdin /usr/local/bin/lid-open <<'EOF'
#!/usr/bin/env bash
for state in /proc/acpi/button/lid/*/state; do
    grep -q open "$state" && exit 0
done
exit 1
EOF

    for svc in sudo polkit-1; do
        f="/etc/pam.d/$svc"
        [[ -f "$f" ]] || printf '#%%PAM-1.0\nauth  include  system-auth\naccount include system-auth\nsession include system-auth\n' | sudo tee "$f" >/dev/null
        grep -q pam_fprintd "$f" && continue
        sudo sed -i -e '1i auth  [success=ignore default=1]  pam_exec.so quiet /usr/local/bin/lid-open' \
                    -e '1i auth  sufficient                   pam_fprintd.so' "$f"
    done

    f="/etc/pam.d/swaylock"
    if ! grep -q pam_fprintd "$f" 2>/dev/null; then
        printf '%s\n' \
            'auth  sufficient                  pam_unix.so try_first_pass nullok' \
            'auth  [success=ignore default=1]  pam_exec.so quiet /usr/local/bin/lid-open' \
            'auth  sufficient                  pam_fprintd.so' \
            'auth  include                     login' | sudo tee "$f" >/dev/null
    fi
}

# =============================================================================
# MEDIA — player, codecs, VA-API hardware decode, image viewer
# =============================================================================
media() {
    msg "media"
    pac mpv ffmpeg gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly gst-libav libva libva-utils playerctl ffmpegthumbnailer swayimg
}

# =============================================================================
# APPS — browsers, 1Password, dev/TUI tools, docker
# =============================================================================
apps() {
    msg "apps"
    pac firefox chromium yazi zathura zathura-pdf-mupdf lazygit lazydocker thunar thunar-volman thunar-archive-plugin tumbler gvfs gvfs-mtp gvfs-gphoto2 gvfs-smb udiskie wf-recorder slurp papirus-icon-theme materia-gtk-theme nwg-look docker docker-compose docker-buildx
    aur 1password 1password-cli

    # docker group applies on next login
    sudo systemctl enable docker.socket
    sudo usermod -aG docker "$USER"
}

# =============================================================================
# LOGIN — ly, niri session auto-discovered
# =============================================================================
login() {
    msg "login"
    pac ly
    sudo systemctl disable getty@tty2.service
    sudo systemctl enable ly@tty2.service

    # auto-unlock gnome-keyring (SSH stays with 1Password)
    grep -q pam_gnome_keyring /etc/pam.d/ly || printf 'auth       optional     pam_gnome_keyring.so\nsession    optional     pam_gnome_keyring.so auto_start\n' | sudo tee -a /etc/pam.d/ly >/dev/null
}

# =============================================================================
# DOTFILES — stow configs into $HOME
# =============================================================================
dotfiles() {
    msg "dotfiles"
    cd "$(dirname "$(readlink -f "$0")")"
    stow -R -t "$HOME" kitty waybar fuzzel mako swaylock lazygit zathura btop bat yazi gtk xdg bin mpv niri zsh git mise nvim fontconfig
    mkdir -p "$HOME/Pictures/Screenshots"

    [ -f "$HOME/.local/share/wallpaper.jpg" ] && magick "$HOME/.local/share/wallpaper.jpg" -resize 1280x -blur 0x18 -brightness-contrast -32x0 "$HOME/.local/share/wallpaper-blur.jpg"

    command -v mise >/dev/null && mise install

    # build bat theme cache (delta uses it too)
    command -v bat >/dev/null && bat cache --build
}

# =============================================================================
# FIRST-BOOT NOTES — printed at the end (steps that can't be scripted)
# =============================================================================
final_notes() {
    cat <<EOF

${c_blue}==>${c_reset} Done. Manual first-boot steps:
  1. 1Password: sign in, then Settings -> Developer -> enable 'Use the SSH agent'
     and 'Sign Git commits' (your ~/.zshenv socket + ~/.gitconfig SSH signing need it).
  2. Enroll a fingerprint:   fprintd-enroll
  3. Log out/in (or 'newgrp docker') so docker group membership applies.
EOF
}

# =============================================================================
# RUN
# =============================================================================
foundation
system
audio
niri
terminal
shell
session
media
apps
login
dotfiles
final_notes
