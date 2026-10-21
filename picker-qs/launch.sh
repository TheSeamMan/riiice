#!/usr/bin/env bash
if pgrep -f "quickshell.*picker-qs" >/dev/null; then
    pkill -f "quickshell.*picker-qs"
    exit 0
fi
exec timeout 300 quickshell -p "$HOME/rice/picker-qs/shell.qml" 2>/tmp/qs-picker.log
