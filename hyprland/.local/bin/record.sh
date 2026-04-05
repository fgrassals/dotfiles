#!/usr/bin/env bash
# Toggle screen recording with wf-recorder.
# Usage: record.sh          — fullscreen
#        record.sh region   — select area with slurp
# Run once to start, again to stop.

if pgrep -x wf-recorder > /dev/null; then
    pkill -INT wf-recorder
    while pgrep -x wf-recorder > /dev/null; do sleep 0.1; done
    notify-send "Screen Recording" "Recording saved to ~/Videos"
else
    output="${XDG_VIDEOS_DIR:-$HOME/Videos}/recording-$(date +%Y%m%d-%H%M%S).mp4"
    if [[ "$1" == "region" ]]; then
        geom=$(slurp) || exit 0
        notify-send "Screen Recording" "Recording started"
        wf-recorder -a -g "$geom" -f "$output"
    else
        notify-send "Screen Recording" "Recording started"
        wf-recorder -a -f "$output"
    fi
fi
