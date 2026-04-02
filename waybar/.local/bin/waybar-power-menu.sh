#!/usr/bin/env bash
# Waybar power menu — opens rofi with session/system options

chosen=$(printf "󰌾  Lock\n󰒲  Suspend\n󰜉  Reboot\n󰐥  Shutdown" | rofi -dmenu -p "Power" -theme-str 'window { width: 200px; }' -i)

case "$chosen" in
    *Lock)     loginctl lock-session ;;
    *Suspend)  systemctl suspend ;;
    *Reboot)   systemctl reboot ;;
    *Shutdown) systemctl poweroff ;;
esac
