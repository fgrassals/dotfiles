# ~/.zshrc
# Sourced for interactive shells only.

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
# MISE — runtime version manager (node, python, etc.)
# Activation must come after zimfw so completions register correctly.
# =============================================================================
eval "$(mise activate zsh)"

# =============================================================================
# EZA — modern ls replacement
# Icons disabled in TTY (no nerd font support in framebuffer)
# =============================================================================
if [[ "$TERM" == "linux" ]]; then
    alias ls='eza --group-directories-first'
    alias ll='eza -lh --group-directories-first --git'
    alias la='eza -lah --group-directories-first --git'
    alias lt='eza --tree --level=2'
else
    alias ls='eza --icons --group-directories-first'
    alias ll='eza -lh --icons --group-directories-first --git'
    alias la='eza -lah --icons --group-directories-first --git'
    alias lt='eza --tree --icons --level=2'
fi

# =============================================================================
# GREP
# =============================================================================
alias grep='grep --color=auto'

# =============================================================================
# FZF — fuzzy finder key bindings
# Ctrl+R  → fuzzy search shell history
# Ctrl+T  → fuzzy insert file path
# Alt+C   → fuzzy cd into subdirectory
# =============================================================================
if command -v fzf &>/dev/null; then
    source <(fzf --zsh)

    # ff    → fuzzy-find a file with a preview (image preview in Kitty, bat elsewhere)
    # eff   → fuzzy-find a file and open it in $EDITOR
    if [[ "$TERM" == "xterm-kitty" ]]; then
        alias ff="fzf --preview 'case \$(file --mime-type -b {}) in image/*) kitty icat --clear --transfer-mode=memory --stdin=no --place=\${FZF_PREVIEW_COLUMNS}x\${FZF_PREVIEW_LINES}@0x0 {} ;; *) bat --style=numbers --color=always {} ;; esac'"
    else
        alias ff="fzf --preview 'bat --style=numbers --color=always {}'"
    fi
    alias eff='$EDITOR "$(ff)"'
fi
