#!/usr/bin/env bash

set -e

COPY_HYPRLAND=false
LOCAL_ONLY=false
DRY_RUN=false
for arg in "$@"; do
    case "$arg" in
        --local) LOCAL_ONLY=true ;;
        --dry-run) DRY_RUN=true ;;
        --integrate-hyprland) COPY_HYPRLAND=true ;;
        -h|--help)
            echo "Kairo — Arch, composed."
            echo "Usage: bash install/install.sh [--local] [--dry-run] [--integrate-hyprland]"
            echo "Default: interactive Arch dependency installation and local shell deployment."
            echo "--local: deploy only; dependencies must already be installed."
            echo "--dry-run: print destinations without writing or contacting the network."
            echo "--integrate-hyprland: back up and copy bundled Hyprland examples (optional)."
            exit 0 ;;
        *) echo "Kairo: unknown installer option: $arg" >&2; exit 1 ;;
    esac
done
if [ "$DRY_RUN" = true ]; then
    printf 'Kairo install from %s\n' "$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")"
    printf 'Application: %s/kairo\n' "${XDG_DATA_HOME:-$HOME/.local/share}"
    printf 'Launchers: %s/{kairo,kairod}\n' "${KAIRO_BIN_DIR:-$HOME/.local/bin}"
    printf 'Settings: %s/kairo/settings.json\n' "${XDG_CONFIG_HOME:-$HOME/.config}"
    printf 'Copy Hyprland examples: %s\nLocal only: %s\n' "$COPY_HYPRLAND" "$LOCAL_ONLY"
    exit 0
fi

# Kairo is installed from this checkout; no published repository is assumed.
INSTALL_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
PROJECT_ROOT="$(dirname "$INSTALL_DIR")"
if [[ ! -f "$PROJECT_ROOT/install/modules/deps.sh" || ! -d "$PROJECT_ROOT/src" ]]; then
    echo "Run bash install/install.sh from a complete Kairo Shell checkout." >&2
    exit 1
fi

export KAIRO_DIR="$PROJECT_ROOT/src"
export I18N_DIR="$PROJECT_ROOT/src/assets/languages"

MODULES_DIR="$INSTALL_DIR/modules"

source "$PROJECT_ROOT/src/scripts/i18n.sh"
source "$MODULES_DIR/deps.sh"
source "$MODULES_DIR/state.sh"
source "$MODULES_DIR/deploy.sh"
source "$MODULES_DIR/version.sh"
source "$MODULES_DIR/config.sh"
source "$MODULES_DIR/service.sh"
if [ "$LOCAL_ONLY" != true ]; then
    source "$MODULES_DIR/ui.sh"
else
    IS_REINSTALL=false
    SELECTED_COMPOSITORS=("hyprland")
fi


if [ "$LOCAL_ONLY" != true ]; then
    check_supported_os
    bootstrap_installer_deps
fi

INSTALL_STATE=$(detect_install_state)
OLD_VERSION=$(get_installed_version)
TARGET_VERSION=$(get_target_version "$PROJECT_ROOT")
TARGET_COMMIT=$(get_target_commit "$PROJECT_ROOT")
OLD_COMMIT=$(get_installed_commit)

if [ "$LOCAL_ONLY" != true ]; then run_installer_ui; fi

TARGET_VERSION=$(get_target_version "$PROJECT_ROOT")
TARGET_COMMIT=$(get_target_commit "$PROJECT_ROOT")


if [ "$LOCAL_ONLY" != true ]; then
    install_dependencies
    [ ${#FAILED_PKGS[@]} -eq 0 ] || { echo "Kairo: dependency installation failed." >&2; exit 1; }
fi

deploy_package "$PROJECT_ROOT" "$OLD_COMMIT" "$TARGET_COMMIT" "$IS_REINSTALL" "$INSTALL_STATE" "${SELECTED_COMPOSITORS[@]}"
if [ "$LOCAL_ONLY" != true ]; then
    setup_sddm "$PROJECT_ROOT"
    install_wallpapers "$INSTALL_FULL_WALLPAPERS"
fi

WALLPAPER_DIR=$(get_wallpaper_dir)
init_kairo_config "$PROJECT_ROOT" "$WALLPAPER_DIR" "$INSTALL_STATE" "$IS_REINSTALL"

if [ "$LOCAL_ONLY" != true ]; then setup_services; fi
write_version_state "$TARGET_VERSION" "$TARGET_COMMIT"

if [[ "$INSTALL_STATE" == "fresh" || "$IS_REINSTALL" == true ]]; then
    rm -f "${XDG_STATE_HOME:-$HOME/.local/state}/kairo/first_launch.done"
fi


if [ "$LOCAL_ONLY" = true ]; then
    echo "Kairo $TARGET_VERSION installed. Start it in Hyprland with kairod start."
else
    draw_completion_screen "$TARGET_VERSION" "$TARGET_COMMIT"
fi
