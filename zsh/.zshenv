# ~/.zshenv
# Sourced for ALL zsh instances — keep this minimal.
# Only things that must be available to non-interactive shells belong here.

export EDITOR=nvim
export VISUAL=nvim

# XDG base dirs
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"

export PATH="$HOME/.local/bin:$PATH"
