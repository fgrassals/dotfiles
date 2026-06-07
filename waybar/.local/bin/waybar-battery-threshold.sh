#!/usr/bin/env bash
# Battery charge threshold toggle
# 80%  — start 50, stop 80  (daily use, protects battery health)
# 100% — start 95, stop 100 (full charge when needed)

current_stop=$(cat /sys/class/power_supply/BAT0/charge_control_end_threshold 2>/dev/null || echo "?")

if [[ "$current_stop" -le 80 ]] 2>/dev/null; then
    active="80"
else
    active="100"
fi

if [[ "$current_stop" -le 80 ]] 2>/dev/null; then
    option1="󰁾  Limit to 80% [active]"
    option2="󰁹  Charge to 100%"
else
    option1="󰁾  Limit to 80%"
    option2="󰁹  Charge to 100% [active]"
fi

chosen=$(printf "%s\n%s" "$option1" "$option2" | rofi -dmenu -p "Battery" -theme-str 'window { width: 420px; }' -i)

case "$chosen" in
    *"Limit to 80%"*)
        sudo set-charge-threshold 80
        notify-send "Battery" "Threshold set to 80% (start: 50%)" --icon=battery
        ;;
    *"Charge to 100%"*)
        sudo set-charge-threshold 100
        notify-send "Battery" "Threshold set to 100% (start: 95%)" --icon=battery
        ;;
esac
