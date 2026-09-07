#!/usr/bin/env bash

detect_install_state() {
    if [ -f "${XDG_STATE_HOME:-$HOME/.local/state}/kairo/version" ]; then
        echo current
    else
        echo fresh
    fi
}
