# ⚡ Linux Wake-on-LAN (WoL) Manager

An interactive CLI tool to manage and persist **Wake-on-LAN (WoL)** settings across reboots on Linux systems (Mint, Ubuntu, Debian, Arch, and others using systemd).

## 📖 Summary
Most Linux network drivers reset the Wake-on-LAN status to disabled (d) every time the system powers down or reboots. Even if you enable it manually with ethtool, the setting is lost during the next boot cycle.

### ⚙️ How it Works
1. **Hardware Discovery**: Scans /sys/class/net to identify physical interfaces, filtering out virtual ones.
2. **Live Detection**: Queries each card using ethtool to show current status.
3. **Persistence**: Creates a systemd service at /etc/systemd/system/wol.service to re-apply settings at boot.

---

## 🛠️ Installation & Usage

### 1. Clone the repository
\`\`\`bash
git clone https://github.com/daniquir/linux-wol-manager.git
cd linux-wol-manager
\`\`\`

### 2. Run the configurator
The script requires root privileges to interact with network hardware and system services.

\`\`\`bash
chmod +x install.sh
sudo ./install.sh
\`\`\`

### 🎮 Interface Controls

| Key | Action |
| :--- | :--- |
| **W / S** or **Arrows** | Move the cursor up/down |
| **Spacebar** | Toggle between **ENABLE [X]** and **DISABLE [ ]** |
| **Enter** | Apply settings, update the system service, and exit |

---

## 📋 Requirements
* **Operating System**: Any Linux distribution using systemd.
* **ethtool**: Core dependency. The script offers to install it if missing.
* **Root Privileges**: Needed to modify system services and network flags.
* **Motherboard Support**:
    * Enable **"Wake on LAN"** or **"PCI-E Resume"** in your BIOS/UEFI.
    * Disable **"Deep Sleep"** or **"ErP Ready"** (to keep the NIC powered).



---

## 🧪 How to Test
1. **Get the MAC Address**: Check the script's output or run \`ip link\`.
2. **Power Off**: Shut down your Linux computer.
3. **Send Packet**: From another device on the same network:
    * **Linux**: \`sudo apt install wakeonlan && wakeonlan [MAC_ADDRESS]\`
    * **Windows**: Use "WakeMeOnLan" or similar.

---

## 📄 Technical Details: wol.service
The script generates a standard systemd unit:

\`\`\`ini
[Unit]
Description=Enable Wake-on-LAN persistently
After=network-online.target

[Service]
Type=oneshot
ExecStart=/bin/true
ExecStartPre=/sbin/ethtool -s eth0 wol g

[Install]
WantedBy=multi-user.target
\`\`\`

---

## 📜 License
This project is licensed under the MIT License.
