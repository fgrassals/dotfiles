#!/usr/bin/env bash
# fuzzel Wi-Fi menu for NetworkManager. Enterprise nets: set up once via `nmtui`.
set -euo pipefail

fz() { fuzzel --dmenu "$@"; }

action=$(printf 'Networks\nToggle Wi-Fi\nDisconnect' | fz --prompt 'wifi> ') || exit 0

case "$action" in
    'Toggle Wi-Fi')
        [ "$(nmcli -t -f WIFI radio wifi)" = enabled ] \
            && nmcli radio wifi off || nmcli radio wifi on
        exit 0 ;;
    'Disconnect')
        con=$(nmcli -t -f NAME,TYPE connection show --active \
              | awk -F: '$2 ~ /wireless/{print $1; exit}')
        [ -n "$con" ] && nmcli connection down "$con"
        exit 0 ;;
    'Networks') ;;
    *) exit 0 ;;
esac

nmcli device wifi rescan 2>/dev/null || true

# SSID is placed last and recovered with awk's last field, so spaces are safe.
sel=$(nmcli -t -f SIGNAL,SECURITY,SSID device wifi list \
      | awk -F: '$3 != "" { printf "%3s%%  %-10s  %s\n", $1, ($2==""?"open":$2), $3 }' \
      | sort -rn | awk '!seen[$0]++' \
      | fz --prompt 'network> ') || exit 0
[ -z "$sel" ] && exit 0

ssid=$(printf '%s' "$sel" | sed -E 's/^[[:space:]]*[0-9]+%[[:space:]]+[^ ]+[[:space:]]+//')
[ -z "$ssid" ] && exit 0

# Known connection (incl. saved enterprise) -> just bring it up.
if nmcli -t -f NAME connection show | grep -Fxq "$ssid"; then
    nmcli connection up "$ssid"
    exit 0
fi

# New network: try open first; if it needs a key, prompt via fuzzel and retry.
if ! nmcli device wifi connect "$ssid" 2>/dev/null; then
    pass=$(: | fz --password --prompt "password for $ssid> ") || exit 0
    [ -z "$pass" ] && exit 0
    nmcli device wifi connect "$ssid" password "$pass"
fi
