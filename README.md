# Linux Wake-on-LAN (WoL) Manager

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Shell](https://img.shields.io/badge/shell-bash-blue.svg)](install.sh)

An interactive CLI tool to manage and persist **Wake-on-LAN (WoL)** settings across reboots on Linux systems (Mint, Ubuntu, Debian, Arch, Fedora, and others using systemd).

## Summary

Most Linux network drivers reset Wake-on-LAN to disabled (`d`) on power-off or reboot. Even if you enable it manually with `ethtool`, the setting is usually lost on the next boot.

### How it works

1. **Hardware discovery** — Scans `/sys/class/net` for physical interfaces, filtering out common virtual/tunnel devices.
2. **Live detection** — Queries each card with `ethtool` and detects whether magic-packet mode (`g`) is active.
3. **Persistence** — Creates a systemd oneshot unit at `/etc/systemd/system/wol.service` to re-apply settings at boot.

---

## Installation and usage

### 1. Clone the repository

```bash
git clone https://github.com/daniquir/linux-wol-manager.git
cd linux-wol-manager
```

### 2. Run the configurator

The script requires root privileges to modify network hardware flags and systemd units.

```bash
chmod +x install.sh
sudo ./install.sh
```

### Interface controls

| Key | Action |
| :--- | :--- |
| **W / S** or **arrow keys** | Move the cursor up/down |
| **Space** | Toggle **ENABLE [X]** / **DISABLE [ ]** |
| **Enter** | Apply settings, update the systemd service, and exit |

---

## Requirements

| Requirement | Notes |
| :--- | :--- |
| **OS** | Linux with **systemd** |
| **ethtool** | Installed automatically when possible (`apt`, `dnf`, `pacman`, `zypper`) |
| **Privileges** | Run as **root** (`sudo`) |
| **BIOS/UEFI** | Enable **Wake on LAN** / **PCI-E resume**; disable **Deep Sleep** / **ErP Ready** where it cuts NIC power |

---

## How to test

1. Note the MAC address from `ip link` or the script output.
2. Shut down the target machine (not just suspend, unless your hardware supports WoL from sleep).
3. From another device on the same LAN, send a magic packet:
   - **Linux:** `sudo apt install wakeonlan && wakeonlan AA:BB:CC:DD:EE:FF`
   - **Windows:** [WakeMeOnLan](https://www.nirsoft.net/utils/wake_on_lan.html) or similar

---

## Generated `wol.service`

The script writes one `ExecStartPre` line per enabled interface, for example:

```ini
[Unit]
Description=Enable Wake-on-LAN persistently
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/bin/true
ExecStartPre=/usr/sbin/ethtool -s enp3s0 wol g

[Install]
WantedBy=multi-user.target
```

To inspect or troubleshoot:

```bash
systemctl status wol.service
journalctl -u wol.service -b
```

---

## Uninstall

```bash
sudo systemctl disable wol.service --now
sudo rm -f /etc/systemd/system/wol.service
sudo systemctl daemon-reload
```

Or run the script again and deselect all interfaces (it removes the unit automatically).

---

## Limitations

- **Driver support** — Not all NICs support WoL; check `ethtool <iface>` for `Supports Wake-on`.
- **NetworkManager** — Some setups may reset `ethtool` flags when the link is managed; if WoL stops working after NM events, you may need extra NM dispatcher hooks (out of scope for this tool).
- **Wi-Fi** — WoL over wireless is uncommon; wired Ethernet is the typical use case.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## Security

See [SECURITY.md](SECURITY.md).

## License

This project is licensed under the [MIT License](LICENSE).

Copyright (c) 2026 Daniel Quirant
