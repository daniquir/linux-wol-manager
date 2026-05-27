# Changelog

All notable changes to this project are documented in this file.

## [Unreleased]

### Fixed

- WoL detection now treats combined modes (e.g. `pg`, `ug`) as enabled when magic packet (`g`) is present.
- Enter key handling on terminals that send carriage return (`\r`).
- Package installation supports `apt`, `dnf`, `pacman`, and `zypper` (not only `apt`).
- Uses resolved `ethtool` path instead of hardcoded `/sbin/ethtool`.
- Validates interface names before writing systemd unit lines.

### Added

- `SECURITY.md`, `CONTRIBUTING.md`, and GitHub Actions ShellCheck workflow.
- README sections for uninstall, limitations, and troubleshooting.
- Broader virtual interface filtering (`tun`, `tap`, `wg`, etc.).
- `Wants=network-online.target` in generated systemd unit.

### Changed

- LICENSE copyright holder updated to Daniel Quirant.

## [1.0.0] - 2026-02-27

### Added

- Initial interactive WoL manager with systemd persistence.
