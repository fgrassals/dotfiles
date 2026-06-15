#!/usr/bin/env bash
# Toggle Wi-Fi radio. Connect to networks with nmtui.
set -uo pipefail

if [ "$(nmcli -t -f WIFI radio wifi)" = enabled ]; then
    nmcli radio wifi off
    notify-send -t 1500 "Wi-Fi" "off"
else
    nmcli radio wifi on
    notify-send -t 1500 "Wi-Fi" "on"
fi
