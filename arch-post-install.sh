#!/usr/bin/env bash
# Arch Linux post-install script
# Packages only — configs managed via GNU Stow
# Run as regular user with sudo access, not root

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
die()     { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# All warnings and post-install notes are collected here and printed at the end
NOTES=()
note() { NOTES+=("$*"); }

[[ $EUID -eq 0 ]] && die "Do not run as root."

# =============================================================================
# WARNINGS
# =============================================================================
echo -e "${YELLOW}"
echo "============================================================"
echo " Before continuing:"
echo ""
echo " 1. Do NOT change the sleep state in BIOS. S3 is not"
echo "    supported on this hardware. Leave it at the default."
echo ""
echo " 2. Do NOT run 'fwupdmgr update' blindly. Check the Arch"
echo "    wiki for your specific model before updating firmware."
echo "============================================================"
echo -e "${NC}"
read -rp "Acknowledged. Continue? [y/N] " confirm
[[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

# =============================================================================
# SYSTEM UPDATE
# =============================================================================
info "Updating system..."
sudo pacman -Syu --noconfirm
success "System updated"

# =============================================================================
# BASE TOOLS
# =============================================================================
info "Installing base tools..."
sudo pacman -S --noconfirm --needed openssh
success "Done"

# =============================================================================
# AUR HELPER — paru
# =============================================================================
info "Installing paru..."
if ! command -v paru &>/dev/null; then
    git clone https://aur.archlinux.org/paru.git /tmp/paru-build
    (cd /tmp/paru-build && makepkg -si --noconfirm)
    rm -rf /tmp/paru-build
fi
success "Done"

# =============================================================================
# AMD GPU — Mesa, Vulkan, VA-API
# =============================================================================
info "Installing AMD GPU stack..."
sudo pacman -S --noconfirm --needed \
    mesa \
    vulkan-radeon \
    libva-utils \
    vulkan-icd-loader \
    libdrm
success "Done"

# =============================================================================
# AUDIO — PipeWire
# =============================================================================
info "Installing PipeWire..."
sudo pacman -S --noconfirm --needed \
    pipewire \
    pipewire-alsa \
    pipewire-audio \
    pipewire-jack \
    pipewire-pulse \
    wireplumber \
    wiremix \
    alsa-utils
systemctl --user enable --now pipewire pipewire-pulse wireplumber
success "Done"

# =============================================================================
# HYPRLAND
# xdg-desktop-portal-hyprland — screen sharing, global shortcuts
# xdg-desktop-portal-gtk      — file picker fallback
# =============================================================================
info "Installing Hyprland..."
sudo pacman -S --noconfirm --needed \
    hyprland \
    hyprlock \
    hypridle \
    swaybg \
    hyprsunset \
    xdg-desktop-portal-hyprland \
    xdg-desktop-portal-gtk \
    xdg-desktop-portal \
    qt5-wayland \
    qt6-wayland \
    wl-clipboard
paru -S --needed hyprshutdown
success "Done"

# =============================================================================
# WAYBAR
# =============================================================================
info "Installing Waybar..."
sudo pacman -S --noconfirm --needed waybar
success "Done"

# =============================================================================
# TERMINAL — foot
# =============================================================================
info "Installing foot..."
sudo pacman -S --noconfirm --needed foot foot-terminfo
success "Done"

# =============================================================================
# LAUNCHER — rofi 2.0
# =============================================================================
info "Installing rofi..."
sudo pacman -S --noconfirm --needed rofi rofi-calc
success "Done"

# =============================================================================
# NOTIFICATIONS — mako
# =============================================================================
info "Installing mako..."
sudo pacman -S --noconfirm --needed mako libnotify
success "Done"

# =============================================================================
# OSD — swayosd
# =============================================================================
info "Installing swayosd..."
sudo pacman -S --noconfirm --needed swayosd
success "Done"

# =============================================================================
# FIREWALL — ufw
# =============================================================================
info "Configuring ufw..."
sudo pacman -S --noconfirm --needed ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw enable
sudo systemctl enable ufw
success "Done"

# =============================================================================
# BLUETOOTH
# =============================================================================
info "Installing Bluetooth..."
sudo pacman -S --noconfirm --needed bluez bluez-utils bluetui
sudo systemctl enable --now bluetooth
success "Done"

# =============================================================================
# BROWSERS + AUR TOOLS
# =============================================================================
info "Installing browsers..."
sudo pacman -S --noconfirm --needed firefox
paru -S --needed google-chrome gazelle-tui
success "Done"

# =============================================================================
# DOCKER
# =============================================================================
info "Installing Docker..."
sudo pacman -S --noconfirm --needed docker docker-compose docker-buildx
sudo usermod -aG docker "$USER"
success "Done"
note "Log out and back in for Docker group membership to take effect"
note "Start Docker manually when needed: sudo systemctl start docker"

# =============================================================================
# MEDIA
# =============================================================================
info "Installing media stack..."
sudo pacman -S --noconfirm --needed \
    mpv \
    ffmpeg \
    gstreamer \
    gst-plugins-base \
    gst-plugins-good \
    gst-plugins-bad \
    gst-plugins-ugly \
    gst-libav \
    libdvdcss \
    x264 \
    x265 \
    libvpx \
    opus \
    aom
success "Done"

# =============================================================================
# FILE MANAGERS — Thunar + yazi
# =============================================================================
info "Installing file managers..."
sudo pacman -S --noconfirm --needed \
    thunar \
    thunar-archive-plugin \
    thunar-media-tags-plugin \
    thunar-volman \
    gvfs-gphoto2 \
    file-roller \
    unzip \
    p7zip \
    gvfs \
    gvfs-mtp \
    gvfs-smb \
    tumbler \
    ffmpegthumbnailer \
    yazi
paru -S --needed unrar
success "Done"

# =============================================================================
# SCREENSHOTS + RECORDING
# =============================================================================
info "Installing screenshot and recording tools..."
sudo pacman -S --noconfirm --needed grim slurp satty wf-recorder jq
success "Done"

# =============================================================================
# IMAGE VIEWER — imv
# =============================================================================
info "Installing imv..."
sudo pacman -S --noconfirm --needed imv
success "Done"

# =============================================================================
# PDF VIEWER — zathura
# =============================================================================
info "Installing zathura..."
sudo pacman -S --noconfirm --needed zathura zathura-pdf-mupdf
success "Done"

# =============================================================================
# FONTS
# =============================================================================
info "Installing fonts..."
sudo pacman -S --noconfirm --needed \
    noto-fonts \
    noto-fonts-cjk \
    noto-fonts-emoji \
    ttf-cascadia-mono-nerd
fc-cache -fv &>/dev/null
success "Done"

# =============================================================================
# KEYRING — gnome-keyring
# =============================================================================
info "Installing gnome-keyring..."
sudo pacman -S --noconfirm --needed gnome-keyring libsecret seahorse

systemctl --user enable gnome-keyring-daemon.socket
success "Done"

# =============================================================================
# 1PASSWORD
# =============================================================================
info "Installing 1Password..."
curl -sS https://downloads.1password.com/linux/keys/1password.asc | gpg --import
paru -S --needed 1password 1password-cli
sudo pacman -S --noconfirm --needed pinentry
success "Done"

# =============================================================================
# POLKIT
# =============================================================================
info "Installing mate-polkit..."
sudo pacman -S --noconfirm --needed mate-polkit
success "Done"

# =============================================================================
# THEMING — GTK + Qt (Catppuccin Macchiato, Papirus icons, Kvantum)
# =============================================================================
info "Installing theming packages..."
sudo pacman -S --noconfirm --needed \
    qt5ct \
    qt6ct \
    kvantum \
    papirus-icon-theme \
    nwg-look
paru -S --needed \
    catppuccin-gtk-theme-macchiato \
    kvantum-theme-catppuccin-git
success "Done"

# =============================================================================
# SYSTEM UTILITIES
# =============================================================================
info "Installing system utilities..."
sudo pacman -S --noconfirm --needed \
    brightnessctl \
    playerctl \
    cliphist \
    udiskie \
    xdg-user-dirs \
    xdg-utils \
    stow \
    upower \
    lm_sensors \
    acpi \
    man-db \
    btop \
    curl \
    wget \
    tmux \
    fzf \
    fd \
    ripgrep \
    eza
xdg-user-dirs-update
success "Done"

# =============================================================================
# PRINTING AND SCANNING — CUPS + HPLIP
# hplip-plugin (AUR) is required for this model — printing and scanning both
# depend on it. hp-setup must be run interactively after reboot to add the
# printer. The hpaio SANE backend is uncommented here for scanner detection.
# =============================================================================
info "Installing CUPS and HPLIP..."
sudo pacman -S --noconfirm --needed cups sane hplip simple-scan
paru -S --needed hplip-plugin

sudo systemctl enable cups.service

# Enable hpaio SANE backend for HP scanners
sudo sed -i 's/^#hpaio/hpaio/' /etc/sane.d/dll.conf

success "Done"
note "Run 'hp-setup' after reboot to add the HP printer to CUPS"
note "Verify scanner with: scanimage -L"

# =============================================================================
# FIRMWARE UPDATES
# =============================================================================
info "Installing fwupd..."
sudo pacman -S --noconfirm --needed fwupd
success "Done"

# =============================================================================
# FINGERPRINT — fprintd + PAM configuration
# =============================================================================
info "Installing fprintd and configuring PAM..."
sudo pacman -S --noconfirm --needed fprintd

sudo tee /usr/local/bin/lid-open > /dev/null << 'EOF'
#!/usr/bin/env bash
for state in /proc/acpi/button/lid/*/state; do
    grep -q "open" "$state" && exit 0
done
exit 1
EOF
sudo chmod 755 /usr/local/bin/lid-open

sudo tee /etc/pam.d/sudo > /dev/null << 'EOF'
#%PAM-1.0
auth  [success=ignore default=1]  pam_exec.so quiet /usr/local/bin/lid-open
auth  sufficient                   pam_fprintd.so
auth  include                      system-auth
account include                    system-auth
session include                    system-auth
EOF

sudo tee /etc/pam.d/polkit-1 > /dev/null << 'EOF'
#%PAM-1.0
auth  [success=ignore default=1]  pam_exec.so quiet /usr/local/bin/lid-open
auth  sufficient                   pam_fprintd.so
auth  include                      system-auth
account include                    system-auth
session include                    system-auth
EOF

sudo tee /etc/pam.d/hyprlock > /dev/null << 'EOF'
#%PAM-1.0
auth  [success=ignore default=1]  pam_exec.so quiet /usr/local/bin/lid-open
auth  sufficient                   pam_fprintd.so
auth  include                      system-auth
account include                    system-auth
session include                    system-auth
EOF

success "fprintd installed and PAM configured"
note "Run 'fprintd-enroll' after reboot to register your fingerprint"

# =============================================================================
# SUDO RULES
# =============================================================================
info "Adding sudo rules..."

# Battery threshold helper — validated root script; NOPASSWD scoped to it only.
sudo tee /usr/local/bin/set-charge-threshold > /dev/null << 'EOF'
#!/usr/bin/env bash
case "$1" in
    80)  start=50; stop=80  ;;
    100) start=95; stop=100 ;;
    *) echo "usage: set-charge-threshold 80|100" >&2; exit 1 ;;
esac
printf 'START_CHARGE_THRESH_BAT0=%s\nSTOP_CHARGE_THRESH_BAT0=%s\n' "$start" "$stop" > /etc/tlp.d/10-battery-threshold.conf
tlp start >/dev/null
EOF
sudo chmod 755 /usr/local/bin/set-charge-threshold

# Name sorts after wheel so this NOPASSWD rule is sudo's last match.
echo "$USER ALL=(ALL) NOPASSWD: /usr/local/bin/set-charge-threshold" | sudo tee /etc/sudoers.d/zz-waybar-battery > /dev/null
sudo chmod 440 /etc/sudoers.d/zz-waybar-battery
success "Done"

# =============================================================================
# NEOVIM — bob + mise + prerequisites
# =============================================================================
info "Installing bob, mise, and neovim prerequisites..."
sudo pacman -S --noconfirm --needed \
    bob \
    lazygit \
    lazydocker \
    mise \
    python \
    tree-sitter-cli
success "Done"
note "Run 'bob install stable' after reboot to install neovim"
note "For node/python via mise: run 'mise use --global node@lts python@latest'"

# =============================================================================
# NVME TWEAKS
# =============================================================================
info "Enabling fstrim.timer..."
sudo systemctl enable fstrim.timer
success "Done"

# =============================================================================
# ZRAM SWAP
# =============================================================================
info "Configuring zram..."
sudo pacman -S --noconfirm --needed zram-generator
sudo tee /etc/systemd/zram-generator.conf > /dev/null << 'EOF'
[zram0]
zram-size = 8192
compression-algorithm = zstd
EOF
echo "vm.swappiness=10" | sudo tee /etc/sysctl.d/99-swappiness.conf > /dev/null
success "Done"

# =============================================================================
# POWER MANAGEMENT — TLP
# =============================================================================
info "Installing TLP..."
sudo pacman -S --noconfirm --needed tlp tlp-rdw
sudo systemctl enable tlp
success "Done"

# =============================================================================
# SHELL — zsh
# =============================================================================
info "Installing zsh extras..."
sudo pacman -S --noconfirm --needed zsh-completions
success "Done"

# =============================================================================
# DISPLAY MANAGER — greetd + nwg-hello
# greetd ships its own greeter user (sysusers) and /etc/pam.d/greetd; we add
# gnome-keyring on top and put the greeter in the video group for GPU access.
# nwg-hello runs under Hyprland via its shipped /etc/nwg-hello/hyprland.conf.
# =============================================================================
info "Installing greetd + nwg-hello..."
sudo pacman -S --noconfirm --needed greetd nwg-hello

sudo usermod -aG video greeter

sudo tee /etc/greetd/config.toml > /dev/null << 'EOF'
[terminal]
vt = 1

[default_session]
command = "start-hyprland -- -c /etc/nwg-hello/hyprland.conf"
user = "greeter"
EOF

sudo tee /etc/pam.d/greetd > /dev/null << 'EOF'
#%PAM-1.0
auth       include      system-login
auth       optional     pam_gnome_keyring.so
account    include      system-login
password   include      system-login
session    include      system-login
session    optional     pam_gnome_keyring.so auto_start
EOF

# Login background dir — owned by the user so set-wallpaper writes it without sudo
sudo mkdir -p /usr/local/share/login-bg
sudo chown "$USER:$USER" /usr/local/share/login-bg

# nwg-hello theme (override files take precedence over *-default)
sudo tee /etc/nwg-hello/nwg-hello.css > /dev/null << 'EOF'
window {
    background-color: #1a1b26;
    background-image: linear-gradient(rgba(0, 0, 0, 0.25), rgba(0, 0, 0, 0.25)), url("/usr/local/share/login-bg/bg-blur.jpg");
    background-size: cover;
    background-position: center;
    color: #c0caf5;
    font-family: "CaskaydiaMono Nerd Font", monospace;
}

/* Frosted panel behind the form */
#form-wrapper {
    background-color: rgba(26, 27, 38, 0.7);
    border-radius: 20px;
    padding: 40px;
    margin: 50px;
}

#welcome-label {
    font-size: 24px;
    color: #c0caf5;
}

#clock-label {
    font-family: "CaskaydiaMono Nerd Font", monospace;
    font-size: 90px;
    color: #c0caf5;
}

#date-label {
    font-size: 22px;
    color: #8f8f8f;
}

/* Password entry */
entry {
    background-color: rgba(255, 255, 255, 0.04);
    color: #c0caf5;
    border: 2px solid #7aa2f7;
    border-radius: 15px;
    padding: 12px;
}

entry:focus {
    border-color: #bb9af7;
}

/* Session combo + login button */
button {
    background: rgba(255, 255, 255, 0.04) none;
    color: #c0caf5;
    border: 2px solid #7aa2f7;
    border-radius: 15px;
    padding: 12px;
}

button:hover {
    background-color: rgba(122, 162, 247, 0.18);
}

/* Power buttons */
#power-button {
    background: none;
    border: none;
    border-radius: 15px;
    color: #c0caf5;
}

#power-button:hover {
    background-color: rgba(255, 255, 255, 0.1);
}

#power-button:active {
    background-color: rgba(187, 154, 247, 0.2);
}
EOF

sudo tee /etc/nwg-hello/nwg-hello.json > /dev/null << 'EOF'
{
  "session_dirs": [
    "/usr/share/wayland-sessions",
    "/usr/share/xsessions"
  ],
  "custom_sessions": [
    {
      "name": "Shell",
      "exec": "/usr/bin/bash"
    }
  ],
  "monitor_nums": [],
  "form_on_monitors": [],
  "delay_secs": 1,
  "cmd-sleep": "systemctl suspend",
  "cmd-reboot": "systemctl reboot",
  "cmd-poweroff": "systemctl poweroff",
  "gtk-theme": "Adwaita",
  "gtk-icon-theme": "",
  "gtk-cursor-theme": "",
  "prefer-dark-theme": true,
  "template-name": "",
  "time-format": "%H:%M",
  "date-format": "%A, %d %B %Y",
  "layer": "overlay",
  "keyboard-mode": "on_demand",
  "lang": "",
  "avatar-show": false,
  "avatar-size": 100,
  "avatar-border-width": 1,
  "avatar-border-color": "#eee",
  "avatar-corner-radius": 15,
  "avatar-circle": false,
  "env-vars": []
}
EOF

sudo systemctl daemon-reload
sudo systemctl enable greetd.service
success "Done"

# =============================================================================
# DOTFILES — Stow + permissions
# Assumes dotfiles repo is at ~/dotfiles.
# Stows every package (subdirectory) found there.
# Makes all scripts in ~/.local/bin executable.
# =============================================================================
info "Setting up dotfiles via Stow..."

DOTFILES_DIR="$HOME/dotfiles"

if [[ ! -d "$DOTFILES_DIR" ]]; then
    warn "~/dotfiles not found — skipping Stow. Run manually when ready:"
    note "cd ~/dotfiles && stow *"
else
    mkdir -p "$HOME/.config/git"
    cd "$DOTFILES_DIR"
    for pkg in */; do
        pkg="${pkg%/}"
        stow "$pkg" && success "Stowed: $pkg" || warn "Stow failed for: $pkg (conflict?)"
    done

    # Make all scripts in ~/.local/bin executable
    if [[ -d "$HOME/.local/bin" ]]; then
        chmod +x "$HOME"/.local/bin/*
        success "chmod +x applied to ~/.local/bin/*"
    fi
fi

# =============================================================================
# DONE
# =============================================================================
echo ""
echo -e "${GREEN}============================================================${NC}"
echo -e "${GREEN}  Install complete.${NC}"
echo -e "${GREEN}============================================================${NC}"
echo ""

if [[ ${#NOTES[@]} -gt 0 ]]; then
    echo -e "${YELLOW}Action required after reboot:${NC}"
    for n in "${NOTES[@]}"; do
        echo -e "  ${YELLOW}→${NC} $n"
    done
    echo ""
fi

echo -e "${YELLOW}Next step:${NC} reboot, then set up dotfiles via Stow."
echo ""
