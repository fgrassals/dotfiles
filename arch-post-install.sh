#!/usr/bin/env bash
# Arch Linux post-install script
# Packages only — configs managed via GNU Stow
# Run as regular user with sudo access, not root

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }
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
# 1. SYSTEM UPDATE
# =============================================================================
info "Updating system..."
sudo pacman -Syu --noconfirm
success "System updated"

# =============================================================================
# 2. BASE TOOLS
# =============================================================================
info "Installing base tools..."
sudo pacman -S --noconfirm --needed git base-devel openssh
success "Done"

# =============================================================================
# 3. AUR HELPER — paru
# =============================================================================
info "Installing paru..."
if ! command -v paru &>/dev/null; then
    git clone https://aur.archlinux.org/paru.git /tmp/paru-build
    (cd /tmp/paru-build && makepkg -si --noconfirm)
    rm -rf /tmp/paru-build
fi
success "Done"

# =============================================================================
# 4. KERNEL PARAMETERS
# amdgpu.dcdebugmask=0x10  — fixes screen flickering on AMD iGPU
# mem_sleep_default=s2idle  — S3 not supported, enforce s2idle
#
# Handles both traditional systemd-boot entries and UKI setups.
# =============================================================================
info "Patching kernel parameters..."
PARAMS="amdgpu.dcdebugmask=0x10 mem_sleep_default=s2idle"

ENTRY=$(ls /boot/loader/entries/*.conf 2>/dev/null | grep -v fallback | head -n1 || true)
if [[ -n "$ENTRY" ]]; then
    if ! grep -q "amdgpu.dcdebugmask" "$ENTRY"; then
        sudo sed -i '/^options/ s/$/ '"$PARAMS"'/' "$ENTRY"
        success "Kernel params added to: $(basename "$ENTRY")"
    else
        success "Kernel params already in systemd-boot entry"
    fi
fi

if [[ ! -f /etc/kernel/cmdline ]] || ! grep -q "amdgpu.dcdebugmask" /etc/kernel/cmdline; then
    echo "$PARAMS" | sudo tee -a /etc/kernel/cmdline > /dev/null
    success "Kernel params written to /etc/kernel/cmdline"
    if [[ -z "$ENTRY" ]]; then
        note "UKI setup detected — run 'sudo mkinitcpio -P' to embed params into the image"
    fi
else
    success "Kernel params already in /etc/kernel/cmdline"
fi

# =============================================================================
# 5. AMD GPU — Mesa, Vulkan, VA-API
# =============================================================================
info "Installing AMD GPU stack..."
sudo pacman -S --noconfirm --needed \
    mesa \
    vulkan-radeon \
    libva-mesa-driver \
    libva-utils \
    vulkan-icd-loader \
    libdrm
success "Done"

# =============================================================================
# 6. AUDIO — PipeWire
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
# 7. HYPRLAND
# xdg-desktop-portal-hyprland — screen sharing, global shortcuts
# xdg-desktop-portal-gtk      — file picker fallback
# =============================================================================
info "Installing Hyprland..."
sudo pacman -S --noconfirm --needed \
    hyprland \
    hyprlock \
    hypridle \
    hyprpaper \
    hyprsunset \
    xdg-desktop-portal-hyprland \
    xdg-desktop-portal-gtk \
    xdg-desktop-portal \
    qt5-wayland \
    qt6-wayland \
    wl-clipboard
success "Done"

# =============================================================================
# 8. WAYBAR
# =============================================================================
info "Installing Waybar..."
sudo pacman -S --noconfirm --needed waybar
success "Done"

# =============================================================================
# 9. TERMINAL — foot
# =============================================================================
info "Installing foot..."
sudo pacman -S --noconfirm --needed foot foot-terminfo
success "Done"

# =============================================================================
# 10. LAUNCHER — rofi 2.0
# =============================================================================
info "Installing rofi..."
sudo pacman -S --noconfirm --needed rofi rofi-calc
success "Done"

# =============================================================================
# 11. NOTIFICATIONS — mako
# =============================================================================
info "Installing mako..."
sudo pacman -S --noconfirm --needed mako libnotify
success "Done"

# =============================================================================
# 12. OSD — swayosd
# =============================================================================
info "Installing swayosd..."
sudo pacman -S --noconfirm --needed swayosd
success "Done"

# =============================================================================
# 13. NETWORK
# =============================================================================
info "Installing NetworkManager..."
sudo pacman -S --noconfirm --needed networkmanager
sudo systemctl enable --now NetworkManager
success "Done"

# =============================================================================
# 14. BLUETOOTH
# =============================================================================
info "Installing Bluetooth..."
sudo pacman -S --noconfirm --needed bluez bluez-utils bluetui
sudo systemctl enable --now bluetooth
success "Done"

# =============================================================================
# 15. BROWSERS + AUR TOOLS
# =============================================================================
info "Installing browsers..."
paru -S --noconfirm --needed brave-bin google-chrome gazelle-tui hyprshutdown
success "Done"

# =============================================================================
# 16. DOCKER
# =============================================================================
info "Installing Docker..."
sudo pacman -S --noconfirm --needed docker docker-compose
sudo usermod -aG docker "$USER"
success "Done"
note "Log out and back in for Docker group membership to take effect"
note "Start Docker manually when needed: sudo systemctl start docker"

# =============================================================================
# 17. MEDIA
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
# 17. FILE MANAGERS — Thunar + yazi
# =============================================================================
info "Installing file managers..."
sudo pacman -S --noconfirm --needed \
    thunar \
    thunar-archive-plugin \
    thunar-media-tags-plugin \
    thunar-volman \
    file-roller \
    unzip \
    p7zip \
    gvfs \
    gvfs-mtp \
    gvfs-smb \
    tumbler \
    ffmpegthumbnailer \
    yazi
paru -S --noconfirm --needed unrar
success "Done"

# =============================================================================
# 18. SCREENSHOTS + RECORDING
# =============================================================================
info "Installing screenshot and recording tools..."
sudo pacman -S --noconfirm --needed grim slurp satty wf-recorder jq
success "Done"

# =============================================================================
# 19. IMAGE VIEWER — imv
# =============================================================================
info "Installing imv..."
sudo pacman -S --noconfirm --needed imv
success "Done"

# =============================================================================
# 20. PDF VIEWER — zathura
# =============================================================================
info "Installing zathura..."
sudo pacman -S --noconfirm --needed zathura zathura-pdf-mupdf
success "Done"

# =============================================================================
# 21. FONTS
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
# 22. KEYRING — gnome-keyring
# =============================================================================
info "Installing gnome-keyring..."
sudo pacman -S --noconfirm --needed gnome-keyring libsecret seahorse

systemctl --user enable gnome-keyring-daemon.socket
success "Done"

# =============================================================================
# 23. 1PASSWORD
# =============================================================================
info "Installing 1Password..."
curl -sS https://downloads.1password.com/linux/keys/1password.asc | gpg --import
paru -S --noconfirm --needed 1password 1password-cli
sudo pacman -S --noconfirm --needed pinentry
success "Done"

# =============================================================================
# 24. POLKIT
# =============================================================================
info "Installing mate-polkit..."
sudo pacman -S --noconfirm --needed mate-polkit
success "Done"

# =============================================================================
# 25. THEMING — GTK + Qt (Catppuccin Macchiato, Papirus icons, Kvantum)
# =============================================================================
info "Installing theming packages..."
sudo pacman -S --noconfirm --needed \
    qt5ct \
    qt6ct \
    kvantum \
    papirus-icon-theme \
    nwg-look
paru -S --noconfirm --needed \
    catppuccin-gtk-theme-macchiato \
    kvantum-theme-catppuccin-git
success "Done"

# =============================================================================
# 26. SYSTEM UTILITIES
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
# 27. PRINTING AND SCANNING — CUPS + HPLIP
# hplip-plugin (AUR) is required for this model — printing and scanning both
# depend on it. hp-setup must be run interactively after reboot to add the
# printer. The hpaio SANE backend is uncommented here for scanner detection.
# =============================================================================
info "Installing CUPS and HPLIP..."
sudo pacman -S --noconfirm --needed cups sane hplip simple-scan
paru -S --noconfirm --needed hplip-plugin

sudo systemctl enable cups.service

# Enable hpaio SANE backend for HP scanners
sudo sed -i 's/^#hpaio/hpaio/' /etc/sane.d/dll.conf

success "Done"
note "Run 'hp-setup' after reboot to add the HP printer to CUPS"
note "Verify scanner with: scanimage -L"

# =============================================================================
# 28. FIRMWARE UPDATES
# =============================================================================
info "Installing fwupd..."
sudo pacman -S --noconfirm --needed fwupd
success "Done"

# =============================================================================
# 28. FINGERPRINT — fprintd + PAM configuration
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
# 29. SUDO RULES
# =============================================================================
info "Adding sudo rules..."

# Battery threshold script — allows writing TLP config and restarting TLP
echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/tee /etc/tlp.d/10-battery-threshold.conf, /usr/bin/tlp" | sudo tee /etc/sudoers.d/waybar-battery > /dev/null
sudo chmod 440 /etc/sudoers.d/waybar-battery
success "Done"

# =============================================================================
# 30. NEOVIM — bob + mise + prerequisites
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
note "For node/python via mise, after dotfiles:"
note "  1. Add 'eval \$(mise activate zsh)' to .zshrc"
note "  2. Run: mise use --global node@lts python@latest"

# =============================================================================
# 31. NVME TWEAKS
# =============================================================================
info "Enabling fstrim.timer..."
sudo systemctl enable fstrim.timer
success "Done"
note "Add 'noatime' to your NVMe root partition in /etc/fstab"
note "  Example: UUID=xxxx / ext4 defaults,noatime 0 1"

# =============================================================================
# 32. POWER MANAGEMENT — TLP
# =============================================================================
info "Installing TLP..."
sudo pacman -S --noconfirm --needed tlp tlp-rdw
sudo systemctl enable tlp
success "Done"

# =============================================================================
# 33. SHELL — zsh
# =============================================================================
info "Installing zsh..."
sudo pacman -S --noconfirm --needed zsh zsh-completions
ZSH_PATH="$(grep '^/.*zsh$' /etc/shells | head -1)"
if [[ -n "$ZSH_PATH" && "$SHELL" != "$ZSH_PATH" ]]; then
    sudo chsh -s "$ZSH_PATH" "$USER"
fi
success "Done"

# =============================================================================
# 34. DISPLAY MANAGER — ly
# =============================================================================
info "Installing ly..."
sudo pacman -S --noconfirm --needed ly

sudo tee /etc/pam.d/ly > /dev/null << 'EOF'
#%PAM-1.0
auth       include      system-login
auth       optional     pam_gnome_keyring.so
account    include      system-login
password   include      system-login
session    include      system-login
session    optional     pam_gnome_keyring.so auto_start
EOF

sudo systemctl daemon-reload
sudo systemctl enable ly@tty2.service
sudo systemctl disable getty@tty2.service
success "Done"

# =============================================================================
# 35. DOTFILES — Stow + permissions
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
