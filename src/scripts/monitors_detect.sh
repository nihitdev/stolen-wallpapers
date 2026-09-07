#!/usr/bin/env bash
VERBOSE=0
if [[ "${1:-}" == "--verbose" ]]; then
    VERBOSE=1
fi

if command -v hyprctl &>/dev/null; then
    if [ "$VERBOSE" -eq 1 ]; then
        out=$(hyprctl monitors 2>/dev/null | awk '/^Monitor /{name=$2; got_mode=0} !got_mode && /^[[:space:]]+[0-9]+x[0-9]+@[0-9.]+/{split($1,a,"@"); printf "%s|%s|%.2f\n", name, a[1], a[2]; got_mode=1}')
    else
        out=$(hyprctl monitors 2>/dev/null | awk '/^Monitor /{print $2}')
    fi
    if [ -n "$out" ]; then
        echo "$out"
        exit 0
    fi
fi

exit 1
