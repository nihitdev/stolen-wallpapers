# Kairo Shell

Kairo is a Hyprland-only desktop shell built with Quickshell/QML, Bash, and Python. It is a modified fork of Serpantinum; see [upstream credits](UPSTREAM.md) and the unchanged [AGPL license](LICENSE.md).

Kairo is currently a local source build. It is **not published on Nixpkgs, the AUR, or another package registry**, and no hosted installer or automatic release-update endpoint is configured.

## Install from this checkout

On Arch Linux and derivatives, from the repository root:

```bash
bash install/install.sh
```

The interactive installer installs dependencies and copies this working tree to `~/.local/share/kairo`, with `kairo` and `kairod` launchers in `~/.local/bin` (and `/usr/local/bin` when permitted). It can back up and install Hyprland configuration and optional system/theme configuration; review its selections before installing. To update, obtain/review source changes and rerun this local installer. Uncommitted source changes are included.

The existing Nix files are local build recipes, not publication claims:

```bash
nix build "path:$PWD"
nix run "path:$PWD" -- --help
```

Local flake outputs include `packages.<system>.kairo`, `apps.<system>.kairod`, `homeManagerModules.kairo`, and `nixosModules.kairo`. The modules expose `programs.kairo`. Point a consumer flake input at `path:/absolute/path/to/kairo-shell` to use them. New files must be included when copying the source; `path:` avoids Git flake filtering of untracked renamed files during review.

## Hyprland integration and commands

Review the [Hyprland configuration](compositors/hyprland) for autostart, clipboard listeners, and keybindings. Keep your monitor/keybinding preferences. Start the shell with:

```bash
kairod start
kairod status
kairod stop
kairo --help
kairo --version
kairo launch start
kairo launch widgetredactor
kairo msg workspace 1
kairo msg workspace 2 move
kairo msg open network wifi
kairo msg toggle launcher
kairo msg close
kairo ipc call main handleCommand toggle launcher ""
kairo kill
```

Use `kairo launch --help`, `kairo msg --help`, `kairo ipc --help`, and `kairod --help` for the implemented command groups. Public script commands are `exit`, `lock`, `volume`, `reload`, `weather`, `location`, `screenshot`, `brightness`, `current_focus`, `monitors_detect`, `location_manual`, and `blue_light_filter`.

Configuration is stored in `~/.config/kairo/settings.json`, caches in `~/.cache/kairo`, state in `~/.local/state/kairo`, runtime files in `$XDG_RUNTIME_DIR/kairo` (fallback `/tmp/kairo`), and daemon PID/lock files in `/tmp/kairod.pid` and `/tmp/kairod.lock`. The exported IPC socket path is `$XDG_RUNTIME_DIR/kairo.sock` (fallback `/tmp/kairo.sock`); commands use Quickshell IPC. Existing upstream user configuration is not automatically moved or deleted.

Existing functional artwork is temporary. See [the asset replacement list](UPSTREAM.md).
