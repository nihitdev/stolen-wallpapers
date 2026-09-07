# Security Policy

Security reports are welcome and should be handled responsibly.

## Supported Versions

Kairo Shell is under active development.

Security fixes generally target the latest version of the `master` branch.

Older revisions may not receive security updates.

## Reporting a Vulnerability

Please do not publicly disclose an unpatched security vulnerability through a GitHub issue.

When possible, use GitHub's private vulnerability reporting functionality for this repository.

A useful report includes:

- A description of the vulnerability
- Affected component
- Steps to reproduce
- Potential impact
- Relevant logs or screenshots
- Suggested mitigation, if known

Do not include credentials, authentication tokens, or unrelated private information.

## Scope

Security-sensitive areas may include:

- Shell command execution
- IPC handling
- Installer behavior
- File permissions
- Configuration parsing
- Lock-screen behavior
- Privilege boundaries
- Network-related components
- External command invocation
- Temporary files
- Update or deployment mechanisms

## Responsible Disclosure

Please allow reasonable time for investigation and remediation before publicly discussing a vulnerability.

After a fix is available, coordinated disclosure is welcome.

## Security Philosophy

Kairo Shell should avoid requiring elevated privileges for normal shell operation.

Components should follow least-privilege principles and avoid executing untrusted input as shell commands.

Security regressions should be treated as higher priority than visual or convenience issues.
