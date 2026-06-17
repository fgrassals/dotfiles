#!/usr/bin/env bash
# wlsunset night light toggle
set -euo pipefail

case "${1:-status}" in
    toggle)
        if pgrep -x wlsunset >/dev/null; then
            pkill -x wlsunset
        else
            wlsunset -t 3500 -T 3501 -S 00:00 -s 23:59 &>/dev/null &
        fi
        pkill -RTMIN+8 waybar || true
        ;;
    status)
        if pgrep -x wlsunset >/dev/null; then
            printf '{"text":"󰖔","tooltip":"Night light on","class":"on"}\n'
        else
            printf '{"text":"󰖕","tooltip":"Night light off","class":"off"}\n'
        fi
        ;;
esac
