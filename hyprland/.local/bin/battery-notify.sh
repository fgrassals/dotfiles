#!/usr/bin/env bash
# Battery level notifier — runs as a daemon via exec-once.
# Fires once per threshold crossing; resets when charging.

bat=""
for b in /sys/class/power_supply/BAT{0,1,2}; do
    [[ -r "$b/capacity" ]] && bat="$b" && break
done
[[ -z "$bat" ]] && exit 0

notified=0  # tracks highest threshold already notified (30, 15, 5)

while sleep 60; do
    pct=$(< "$bat/capacity")
    status=$(< "$bat/status")

    if [[ "$status" != "Discharging" ]]; then
        notified=0
        continue
    fi

    if   [[ $pct -le 5  && $notified -lt 5  ]]; then
        notify-send -u critical -t 0 "Battery Critical" "${pct}% — plug in now"
        notified=5
    elif [[ $pct -le 15 && $notified -lt 15 ]]; then
        notify-send -u critical "Battery Low" "${pct}% remaining"
        notified=15
    elif [[ $pct -le 30 && $notified -lt 30 ]]; then
        notify-send -u normal "Battery Warning" "${pct}% remaining"
        notified=30
    fi
done
