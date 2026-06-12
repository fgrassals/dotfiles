#!/usr/bin/env bash
# Toggle / report wlsunset night light for waybar. Times are local; tweak to taste.
set -euo pipefail

case "${1:-status}" in
    toggle)
        if pgrep -x wlsunset >/dev/null; then
            pkill -x wlsunset
        else
            wlsunset -S 06:30 -s 19:00 &>/dev/null &
        fi
        ;;
    status)
        if pgrep -x wlsunset >/dev/null; then
            printf '{"text":"","tooltip":"Night light on","class":"on"}\n'
        else
            printf '{"text":"","tooltip":"Night light off","class":"off"}\n'
        fi
        ;;
esac
