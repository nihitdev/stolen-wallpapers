# Changelog

All notable changes to Kairo Shell are documented here.

Kairo Shell is a modified continuation of Serpantinum. Historical upstream
entries are intentionally preserved where relevant for attribution and project
history.

## Unreleased

### Added

- Kairo Shell branding and project identity
- `kairo` command-line interface
- `kairod` shell daemon
- Kairo-specific configuration under `~/.config/kairo`
- Hyprland-focused shell integration
- Migration regression tests
- Local installation workflow
- Kairo documentation and community files
- GitHub issue and pull request templates

### Changed

- Renamed Serpantinum user-facing components to Kairo
- Migrated application data to Kairo-specific paths
- Migrated shell configuration to the Kairo namespace
- Updated Quickshell modules and runtime paths
- Updated installer and Nix packaging
- Updated theme, wallpaper, lock screen, launcher, clipboard, notification,
  system panel, and shell integration components
- Updated visible project branding for Kairo
- Focused compositor integration on Hyprland

### Removed

- Niri-specific integration
- Sway-specific integration
- Legacy updater implementation
- Legacy telemetry-related installer functionality
- Serpantinum-specific runtime command paths

### Fixed

- License metadata to correctly reflect AGPL-3.0-or-later
- Migration path consistency
- CLI and daemon naming consistency
- Hyprland integration paths
- Installer deployment paths

---

<!-- Historical upstream changelog entries continue below this line. -->
