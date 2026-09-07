# Kairo migration review

Changes are uncommitted. The application retains its QML UI architecture and Hyprland dispatch implementation.

## Changes

- Rebranded commands, UI strings in all eight translations, QML properties/types/imports, environment variables, installer paths, Matugen template paths, local Nix package/flake/module/service names, and IPC examples.
- Removed the Niri and Sway compositor directories and their workspace, monitor, keyboard, idle, screenshot, focus tracking, logout, and installer selection branches. Daemon startup requires a Hyprland session.
- Kept `swaylock` detection because it is a standalone lock program usable under Hyprland, not Sway compositor support. Shared Wayland protocols and generic init-system integration remain.
- Installer uses this checkout, including uncommitted changes, and has no assumed hosted fork repository. Remote update checks and upstream telemetry are disabled. Local Nix recipes remain available; README explicitly states that no Kairo package has been published.
- Corrected the advertised `exit` command to use the existing `scripts/system/exit.sh` implementation.
- Preserved LICENSE.md and upstream CHANGELOG.md byte-for-byte; preserved contributor history and third-party theme attribution. Corrected local package metadata from MIT to AGPL-3.0-only. Installed copies include license and attribution documents.

## Renamed files and directories

The upstream-branded paths now use:

- `bin/kairo` and `bin/kairod`
- `config/kairo/`
- `src/assets/matugen/templates/kairo_matugen_colors.json.template`
- `src/quickshell/kairo/` (formerly the abbreviated `serp` directory), with `Kairo.qml` and `Start.qml`
- `src/assets/sounds/start/transition_kairo.wav` (formerly `transition_serp.wav`; audio unchanged)

All former shell commands now start with `kairo`; daemon commands start with `kairod`. Subcommands remain the existing implementation's commands.

Paths now use `kairo` beneath config, cache, state, local share, and runtime directories. See README for exact defaults. Daemon files are `/tmp/kairod.pid` and `/tmp/kairod.lock`; the exported socket is `$XDG_RUNTIME_DIR/kairo.sock`. Environment variables use the `KAIRO_` prefix. Home Manager uses `programs.kairo` and `kairo.service`. Existing user configuration is not automatically relocated.

## Validation

- Local Nix package build: passed on x86_64-linux.
- `nix flake check "path:$PWD" --no-build`: passed; conventional Home Manager output and missing app metadata warnings remain. aarch64 was not built.
- Bash syntax checks for shell scripts and both launchers: passed.
- `shellcheck -s bash -S error` for launchers, installer/modules, main/system scripts, and watchers: passed. Explicit Bash mode is required for pre-existing files without shebangs.
- Python syntax parsing: passed.
- Translation JSON parsing: all eight passed. Repository-wide JSON parsing found the pre-existing empty `src/assets/themes/Nightfox.json`, left unchanged.
- CLI main/launch/msg/IPC help, daemon help, versions, and unknown-command rejection in temporary XDG directories: passed.
- Mocked Hyprland workspace switching/moving and Quickshell open/toggle/close IPC routing: passed.
- Local updater reports no available remote release: passed.
- QML file-target checks for every qmldir: passed.
- `qmlformat` validation of 157 QML files: 146 passed. The same 11 files fail against the untouched baseline: Main.qml, bar/Bar.qml, reusables/PasswordInput.qml, idle/Idle.qml, network/NetworkPopup.qml, lock/Lock.qml, notifications/NotificationManager.qml, screenshot/ScreenshotOverlay.qml, singletons/audio/Audio.qml, singletons/theme/Wallpaper.qml, and singletons/widgetcontrols/WidgetSync.qml. No additional migration failures remain. This is not a full runtime UI validation.
- `git diff --check`: passed.

## Remaining references and manual work

Old full-name references remain only in README.md and UPSTREAM.md as attribution, and CHANGELOG.md as historical release notes. Git history and origin metadata are unchanged. There are no old full-name files or operational references.

Replace the retained logo/banner and refresh screenshots listed in UPSTREAM.md. Test the shell interactively in Hyprland, including lock/unlock, monitor controls, workspace navigation, and both bar orientations. The system installer was inspected but not executed against the host. Review the baseline QML validation failures and empty theme separately. No release repository or package registry has been invented or configured.
