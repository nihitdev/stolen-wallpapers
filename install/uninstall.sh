#!/usr/bin/env bash
set -e

DRY_RUN=false
PURGE=false
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        --purge) PURGE=true ;;
        -h|--help)
            echo 'Usage: bash install/uninstall.sh [--dry-run] [--purge]'
            echo 'Remove a checkout-installed Kairo shell and its owned launchers/assets.'
            echo 'Settings, cache and state are retained unless --purge is supplied.'
            echo 'Hyprland configuration and system dependencies are never removed.'
            exit 0 ;;
        *) echo "Kairo: unknown removal option: $arg" >&2; exit 1 ;;
    esac
done

data_base="${XDG_DATA_HOME:-$HOME/.local/share}"
install_dir="$data_base/kairo"
bin_dir="${KAIRO_BIN_DIR:-$HOME/.local/bin}"
if [ ! -f "$install_dir/.kairo-install" ] && [ ! -f "$install_dir/bin/kairod" ]; then
    echo "Kairo: no managed checkout installation at $install_dir" >&2
    exit 1
fi

printf 'Remove Kairo installation: %s\n' "$install_dir"
printf 'Remove owned launchers in: %s\n' "$bin_dir"
printf 'Purge settings/cache/state: %s\n' "$PURGE"
[ "$DRY_RUN" = false ] || exit 0

"$install_dir/bin/kairod" stop
for name in kairo kairod; do
    for path in "$bin_dir/$name" "/usr/local/bin/$name"; do
        if [ -L "$path" ] && [ "$(readlink "$path")" = "$install_dir/bin/$name" ]; then
            if ! rm "$path"; then
                echo "Kairo: remove this owned launcher manually: $path" >&2
                exit 1
            fi
        fi
    done
done
for path in "$data_base/applications/kairo.desktop" "$data_base/icons/hicolor/scalable/apps/kairo.svg"; do
    if [ -L "$path" ] && [[ "$(readlink "$path")" == "$install_dir/"* ]]; then rm "$path"; fi
done
rm -rf "$install_dir"
if [ "$PURGE" = true ]; then
    rm -rf "${XDG_CONFIG_HOME:-$HOME/.config}/kairo" \
           "${XDG_CACHE_HOME:-$HOME/.cache}/kairo" \
           "${XDG_STATE_HOME:-$HOME/.local/state}/kairo"
fi
echo 'Kairo removed. Hyprland configuration and dependencies were retained.'
