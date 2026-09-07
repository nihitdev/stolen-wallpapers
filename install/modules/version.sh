#!/usr/bin/env bash

MODULE_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
if [ -z "$KAIRO_DIR" ]; then
    if [ -d "$(dirname "$(dirname "$MODULE_DIR")")/src" ]; then
        export KAIRO_DIR="$(dirname "$(dirname "$MODULE_DIR")")/src"
    fi
fi

if [ -n "$KAIRO_DIR" ] && [ -f "$KAIRO_DIR/scripts/caching.sh" ]; then
    source "$KAIRO_DIR/scripts/caching.sh"
fi

STATE_DIR="${QS_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/kairo}"
VERSION_FILE="$STATE_DIR/version"
DEFAULT_FALLBACK_VERSION="2.0.0"

get_installed_version() {
    local ver=""
    if [ -f "$VERSION_FILE" ]; then
        ver=$(awk -F= '/^KAIRO_VERSION=/{gsub(/"/, "", $2); print $2}' "$VERSION_FILE")
    fi
    if [ -z "$ver" ] && [ -n "$KAIRO_VERSION" ]; then
        ver="$KAIRO_VERSION"
    fi
    if [ -z "$ver" ]; then
        if [ -n "$KAIRO_DIR" ] && [ -f "$KAIRO_DIR/version.txt" ]; then
            ver=$(cat "$KAIRO_DIR/version.txt" 2>/dev/null | xargs)
        elif [ -n "$KAIRO_DIR" ] && [ -f "$(dirname "$KAIRO_DIR")/version.txt" ]; then
            ver=$(cat "$(dirname "$KAIRO_DIR")/version.txt" 2>/dev/null | xargs)
        elif [ -n "$REPO_ROOT" ] && [ -f "$REPO_ROOT/version.txt" ]; then
            ver=$(cat "$REPO_ROOT/version.txt" 2>/dev/null | xargs)
        fi
    fi
    if [ -z "$ver" ]; then
        ver="$DEFAULT_FALLBACK_VERSION"
    fi
    echo "$ver"
}

get_installed_commit() {
    if [ -f "$VERSION_FILE" ]; then
        awk -F= '/^KAIRO_COMMIT=/{gsub(/"/, "", $2); print $2}' "$VERSION_FILE"
    fi
}

get_target_version() {
    local ver
    ver=$(cat "$1/version.txt" 2>/dev/null | xargs)
    echo "${ver:-$DEFAULT_FALLBACK_VERSION}"
}

get_target_commit() {
    local commit
    commit=$(git -C "$1" rev-parse --short HEAD 2>/dev/null || true)
    echo "${commit:-unknown}"
}

write_version_state() {
    mkdir -p "$STATE_DIR"
    local tmp_file="${VERSION_FILE}.tmp.$$"
    cat <<EOF > "$tmp_file"
KAIRO_VERSION="${1:-unknown}"
KAIRO_COMMIT="${2:-unknown}"
COMPOSITOR="hyprland"
EOF
    mv -f "$tmp_file" "$VERSION_FILE"
}
