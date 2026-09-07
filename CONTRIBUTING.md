# Contributing to Kairo Shell

Thanks for your interest in contributing to Kairo Shell.

Kairo Shell is an open-source desktop shell for Hyprland focused on a cohesive interface, customization, reliability, and a clean desktop experience.

Contributions of all sizes are welcome: bug fixes, QML improvements, documentation, translations, themes, testing, performance improvements, and new ideas.

## Before You Start

Before making a large change, check existing issues and discussions to see whether the idea is already being worked on.

For substantial features or architectural changes, opening an issue first is recommended.

Small fixes do not require an issue.

## Development Setup

Clone the repository:

```bash
git clone https://github.com/nihitdev/kairo-shell.git
cd kairo-shell
```

Install the current checkout:

```bash
bash install/install.sh --local
```

Start Kairo:

```bash
kairod start
```

Restart after making runtime changes:

```bash
kairod stop
kairod start
```

## Project Structure

```text
bin/                 CLI and daemon entrypoints
config/kairo/        Default configuration
install/             Installer
nix/                 Nix packaging and modules
src/assets/          Themes, translations and assets
src/quickshell/      Quickshell/QML shell
src/scripts/         Helper scripts
tests/               Regression tests
docs/                Documentation and images
```

## Development Guidelines

Keep changes focused.

Avoid unrelated formatting or refactoring in the same pull request.

Preserve compatibility where practical.

Do not remove upstream attribution or licensing information.

Kairo Shell currently targets Hyprland. Do not introduce compositor-specific implementations for unsupported compositors without prior discussion.

Prefer existing project patterns before introducing additional dependencies or abstractions.

## Testing

Run the migration regression tests:

```bash
/usr/bin/python3 -m pytest -q tests/test_migration.py
```

Check Git whitespace:

```bash
git diff --check
```

Check the CLI:

```bash
kairo --version
kairod --version
```

When changing QML or runtime behavior, test the shell inside a real Hyprland session.

## Commit Messages

Focused commits are preferred.

Examples:

```text
fix(launcher): prevent duplicate search results
feat(theme): add monochrome Kairo preset
docs: document Hyprland integration
refactor(audio): simplify volume state handling
test: cover migrated configuration paths
```

Avoid commits such as:

```text
stuff
changes
fix
update
asdf
```

## Pull Requests

A good pull request should explain:

- What changed
- Why the change is useful
- How it was tested
- Whether configuration behavior changed
- Whether new dependencies were introduced

Screenshots or recordings are strongly encouraged for visible UI changes.

Keep pull requests reasonably focused so they can be reviewed independently.

## Bug Reports

Useful bug reports include:

- Kairo Shell version
- Hyprland version
- Quickshell version
- Distribution
- Relevant logs
- Steps to reproduce
- Expected behavior
- Actual behavior

Remove passwords, tokens, private paths, or other sensitive information before posting logs.

## Feature Requests

Feature requests are welcome.

Explain the problem or workflow the feature would improve rather than only describing an implementation.

## Translations

Translation improvements are welcome.

Language resources are located under:

```text
src/assets/languages/
```

Try to preserve existing keys and structure.

## Themes

Theme contributions should remain readable across the entire shell rather than optimizing only one component.

Check text contrast, selected states, notifications, popups, launcher results, system panels, and lock-screen elements.

## Licensing

Kairo Shell is licensed under AGPL-3.0-or-later.

By contributing, you agree that your contribution may be distributed under the project's license.

Code derived from upstream Serpantinum remains subject to its applicable copyright and attribution requirements.

See `LICENSE` and `UPSTREAM.md`.

## Questions

If you are unsure whether a change fits Kairo Shell, open an issue and describe what you want to build.

Thanks for helping improve Kairo Shell.
