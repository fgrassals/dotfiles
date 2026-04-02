#!/usr/bin/env bash
# Toggle internal laptop display on/off
if hyprctl monitors | grep -q "^Monitor eDP-1"; then
    hyprctl keyword monitor eDP-1,disable
else
    hyprctl keyword monitor eDP-1,1920x1200@60,auto-right,1.5
fi
