# Upstream attribution

Kairo Shell is a modified fork of [Serpantinum](https://github.com/ilyamiro/serpantinum), by ilyamiro and its contributors. The original contributor history remains in Git; CHANGELOG.md records upstream releases and is preserved unchanged.

The upstream GNU Affero General Public License version 3 is preserved in LICENSE.md. Kairo's local Nix metadata uses AGPL-3.0-only, matching the supplied license rather than the upstream packaging's erroneous MIT declaration.

Fork modifications (2026-09-07): Kairo branding and paths, Hyprland-only support, checkout-based installation, and disabled upstream release checks and telemetry. This fork has no published package or release endpoint.

Existing artwork, sounds, previews, SDDM theme credits, and third-party dependencies retain their upstream attribution. The optional wallpaper collection remains sourced from ilyamiro/shell-wallpapers; it is not a published Kairo package.

Artwork awaiting replacement:
- src/assets/kairo-logo.svg — existing upstream logo used in the UI.
- docs/assets/kairo-banner.png — upstream banner, retained but no longer displayed in the README.
- docs/assets/previews/preview_1.png through preview_4.png — historical upstream screenshots; regenerate after visual validation.
- src/assets/sounds/start/transition_kairo.wav — retained upstream startup audio (renamed only).
