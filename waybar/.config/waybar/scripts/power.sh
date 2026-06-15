#!/usr/bin/env bash
set -euo pipefail

choice=$(printf '󰌾  Lock\n󰍃  Logout\n󰒲  Suspend\n󰜉  Reboot\n󰐥  Shutdown' | fuzzel --dmenu --prompt 'power: ' --lines 5)

case "$choice" in
    *Lock)     loginctl lock-session ;;
    *Logout)   niri msg action quit ;;
    *Suspend)  systemctl suspend ;;
    *Reboot)   systemctl reboot ;;
    *Shutdown) systemctl poweroff ;;
esac
