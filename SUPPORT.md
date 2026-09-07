# Kairo Shell Support

Having trouble with Kairo Shell? This document explains where to start.

## Before Opening an Issue

Check that you are running a recent version of Kairo Shell.

Check the daemon:

```bash
kairod status
```

Try restarting it:

```bash
kairod stop
kairod start
```

Check the CLI:

```bash
kairo --version
kairod --version
```

If you installed from a local checkout, reinstall it:

```bash
bash install/install.sh --local
```

## Collecting Information

When reporting a problem, include:

```text
Kairo Shell version:
Hyprland version:
Quickshell version:
Linux distribution:
Installation method:
```

Also include the steps required to reproduce the problem.

If the shell produces useful terminal output, include the relevant section.

## Configuration Problems

Kairo user configuration normally lives under:

```text
~/.config/kairo/
```

Application files normally live under:

```text
~/.local/share/kairo/
```

Runtime state may exist under:

```text
~/.local/state/kairo/
```

When reporting configuration problems, mention whether the issue also occurs with the default configuration.

## Bugs

Use the GitHub bug report template.

Provide enough information for another person to reproduce the issue.

## Feature Requests

Use the feature request template.

Describe the workflow or problem you want improved.

## Security Problems

Do not open a normal public issue for an unpatched security vulnerability.

Read `SECURITY.md` instead.

## Upstream Issues

Kairo Shell originated as a modified fork of Serpantinum.

If a problem is clearly inherited from upstream code, it can still be reported to Kairo Shell. Mentioning that the behavior also exists upstream can help investigation.
