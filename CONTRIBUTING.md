# Contributing

Thank you for improving Linux WoL Manager.

## Getting started

1. Fork the repository and clone your fork.
2. Make changes on a feature branch.
3. Test on a real Linux host with `sudo ./install.sh` when your change affects runtime behavior.
4. Open a pull request against `main` with a clear description and test notes.

## Code guidelines

- Keep `install.sh` POSIX-friendly bash where possible; avoid unnecessary dependencies.
- Match existing style: clear user messages, minimal scope per change.
- Do not commit machine-specific paths, logs, or generated `wol.service` files from your system.

## Pull requests

- One logical change per PR when practical.
- Update `README.md` if behavior or requirements change.
- Mention distribution tested (e.g. Ubuntu 24.04, Arch).

## Issues

When reporting bugs, include:

- Distribution and version
- Output of `ethtool <interface> | grep -i wake`
- Whether NetworkManager or similar manages the interface
- Relevant `journalctl -u wol.service -b` lines if persistence fails
