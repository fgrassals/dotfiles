#!/usr/bin/env bash
# Handle laptop lid open/close events.
# Usage: lid-switch.sh close | open

case "$1" in
    close)
        # External connected → disable laptop; otherwise just lock
        if [[ $(hyprctl monitors -j | jq 'length') -gt 1 ]]; then
            hyprctl keyword monitor "eDP-1,disable"
        else
            loginctl lock-session
        fi
        ;;
    open)
        # Re-enable laptop if it was disabled
        if ! hyprctl monitors | grep -q "^Monitor eDP-1"; then
            hyprctl keyword monitor "eDP-1,1920x1200@60,auto-right,1.25"
        fi
        ;;
esac
