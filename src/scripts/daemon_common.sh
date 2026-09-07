#!/usr/bin/env bash
# Shared lifecycle helpers; only the daemon recorded in our runtime directory is managed.

kairo_pid_alive() {
    local pid="$1"
    [[ "$pid" =~ ^[0-9]+$ ]] && [ "$pid" -gt 1 ] || return 1
    kill -0 "$pid" 2>/dev/null || return 1
    ! grep -q '^State:[[:space:]]*Z' "/proc/$pid/status" 2>/dev/null
}

kairo_daemon_pid() {
    local pid command_line
    [ -r "$KAIRO_PID_FILE" ] || return 1
    read -r pid < "$KAIRO_PID_FILE" || return 1
    kairo_pid_alive "$pid" || return 1
    command_line=$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null) || return 1
    case "$command_line" in
        *"/kairod "*|*"/.kairod-wrapped "*) printf '%s\n' "$pid" ;;
        *) return 1 ;;
    esac
}

kairo_children() {
    local child
    for child in $(pgrep -P "$1" 2>/dev/null); do
        kairo_children "$child"
        printf '%s\n' "$child"
    done
}

get_installed_version() {
    local file ver
    if [ -n "${KAIRO_VERSION:-}" ]; then printf '%s\n' "$KAIRO_VERSION"; return; fi
    for file in "$KAIRO_DIR/version.txt" "$KAIRO_DIR/../version.txt"; do
        if [ -s "$file" ]; then cat "$file"; return; fi
    done
    if [ -f "$QS_STATE_DIR/version" ]; then
        ver=$(awk -F= '/^KAIRO_VERSION=/{gsub(/[" ]/, "", $2); print $2}' "$QS_STATE_DIR/version")
    fi
    printf '%s\n' "${ver:-unknown}"
}
