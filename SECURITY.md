# Security Policy

## Supported versions

Security fixes are applied to the latest release on the `main` branch.

## Reporting a vulnerability

If you discover a security issue, please **do not** open a public GitHub issue with exploit details.

Instead, open a [private security advisory](https://github.com/daniquir/linux-wol-manager/security/advisories/new) on GitHub, or contact the maintainer through GitHub.

## Scope and trust model

This tool is intended to be run **as root** on systems you administer. It:

- Writes `/etc/systemd/system/wol.service`
- Runs `ethtool` on network interfaces discovered under `/sys/class/net`
- May install `ethtool` via the system package manager when you confirm

Only run it from a trusted copy of this repository. Review `install.sh` before executing with `sudo`.

## Hardening notes

- Interface names are validated (`^[a-zA-Z0-9._-]+$`) before being written into the systemd unit.
- `ExecStartPre` lines are built with `printf` and the resolved `ethtool` path, not unquoted shell expansion in the unit file.
