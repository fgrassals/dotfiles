# ~/.zshrc
# Sourced for interactive shells only.

# =============================================================================
# HYPRLAND AUTOSTART
# Avoids loading zimfw needlessly.
# =============================================================================
if [[ -z $WAYLAND_DISPLAY && -z $DISPLAY && $(tty) = /dev/tty1 ]]; then
    exec start-hyprland
fi

# =============================================================================
# ZIMFW bootstrap
# =============================================================================
ZIM_HOME="$XDG_DATA_HOME/zim"

# Download zimfw.zsh if not present
if [[ ! -e "$ZIM_HOME/zimfw.zsh" ]]; then
    mkdir -p "$ZIM_HOME"
    curl -fsSL -o "$ZIM_HOME/zimfw.zsh" \
        https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
fi

# Install missing modules and rebuild init.zsh if .zimrc is newer
if [[ ! "$ZIM_HOME/init.zsh" -nt "${ZDOTDIR:-$HOME}/.zimrc" ]]; then
    source "$ZIM_HOME/zimfw.zsh" init -q
fi

source "$ZIM_HOME/init.zsh"

# =============================================================================
# PATH
# =============================================================================
# bob-managed neovim binary
export PATH="$XDG_DATA_HOME/bob/nvim-bin:$PATH"

# =============================================================================
# MISE — runtime version manager (node, python, etc.)
# Activation must come after zimfw so completions register correctly.
# =============================================================================
eval "$(mise activate zsh)"

# =============================================================================
# EZA — modern ls replacement
# =============================================================================
alias ls='eza --icons --group-directories-first'
alias ll='eza -lh --icons --group-directories-first --git'
alias la='eza -lah --icons --group-directories-first --git'
alias lt='eza --tree --icons --level=2'

# =============================================================================
# FZF — fuzzy finder key bindings
# Ctrl+R  → fuzzy search shell history
# Ctrl+T  → fuzzy insert file path
# Alt+C   → fuzzy cd into subdirectory
# =============================================================================
if command -v fzf &>/dev/null; then
    source <(fzf --zsh)
fi
