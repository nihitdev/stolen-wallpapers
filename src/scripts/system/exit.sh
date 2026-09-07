#!/usr/bin/env bash

if command -v systemctl &>/dev/null; then
    systemctl --user stop graphical-session.target 2>/dev/null
    systemctl --user stop graphical-session-pre.target 2>/dev/null
fi

if command -v dinitctl &>/dev/null; then
    dinitctl --user stop graphical-session 2>/dev/null
fi

sleep 0.2

if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ] || pgrep -x Hyprland &>/dev/null; then
    hyprctl dispatch 'hl.dsp.exit()' 2>/dev/null || \
    pkill -SIGTERM -x Hyprland 2>/dev/null
fi
