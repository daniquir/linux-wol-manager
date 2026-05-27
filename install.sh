#!/bin/bash

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
  echo "❌ Error: Please run this script as root (sudo)."
  exit 1
fi

install_ethtool() {
  if command -v apt-get &>/dev/null; then
    apt-get update && apt-get install -y ethtool
  elif command -v dnf &>/dev/null; then
    dnf install -y ethtool
  elif command -v pacman &>/dev/null; then
    pacman -Sy --noconfirm ethtool
  elif command -v zypper &>/dev/null; then
    zypper install -y ethtool
  else
    echo "❌ Could not detect a supported package manager."
    echo "   Please install ethtool manually and run this script again."
    exit 1
  fi
}

# Check if ethtool is installed
if ! command -v ethtool &>/dev/null; then
  echo "📦 'ethtool' is not installed."
  read -r -p "Do you want to install it now? (y/n): " confirm
  if [[ $confirm == [yY] ]]; then
    install_ethtool
  else
    echo "Exiting: ethtool is required."
    exit 1
  fi
fi

ETHTOOL=$(command -v ethtool)

# Returns 0 if magic-packet WoL (g) is active on the interface
is_wol_enabled() {
  local iface=$1
  local mode
  mode=$("$ETHTOOL" "$iface" 2>/dev/null | awk -F': ' '/^Wake-on: / {print $2; exit}')
  [[ -n "$mode" && "$mode" == *g* ]]
}

valid_iface() {
  [[ "$1" =~ ^[a-zA-Z0-9._-]+$ ]]
}

# Physical interfaces only (exclude common virtual/tunnel names)
interfaces=()
while IFS= read -r iface; do
  valid_iface "$iface" || continue
  interfaces+=("$iface")
done < <(ls /sys/class/net | grep -vE '^(lo|docker|vbox|virbr|veth|br|tun|tap|wg|tailscale|zt)')

if [ ${#interfaces[@]} -eq 0 ]; then
  echo "No compatible network interfaces found."
  exit 1
fi

selected=()
current_status=()

for i in "${!interfaces[@]}"; do
  if is_wol_enabled "${interfaces[$i]}"; then
    current_status[$i]="Enabled"
    selected[$i]=1
  else
    current_status[$i]="Disabled"
    selected[$i]=0
  fi
done

cursor=0

draw_menu() {
  clear
  echo "--- WAKE-ON-LAN MANAGER ---"
  echo "Select interfaces to ENABLE WoL. Unselected will be DISABLED."
  echo "------------------------------------------------------------"
  echo "Controls: [W/S] Up/Down, [SPACE] Toggle, [ENTER] Apply & Save"
  echo "------------------------------------------------------------"
  for i in "${!interfaces[@]}"; do
    if [ "$i" -eq "$cursor" ]; then
      prefix=" > "
    else
      prefix="   "
    fi

    if [ "${selected[$i]}" -eq 1 ]; then
      symbol="[X] ENABLE "
    else
      symbol="[ ] DISABLE"
    fi

    echo "$prefix $symbol ${interfaces[$i]}  (Current: ${current_status[$i]})"
  done
  echo "------------------------------------------------------------"
}

while true; do
  draw_menu
  IFS= read -rsn1 key
  case "$key" in
    $'\x1b')
      read -rsn2 -t 0.1 key
      case "$key" in
        "[A") ((cursor--)) || true ;;
        "[B") ((cursor++)) || true ;;
      esac
      ;;
    w | W) ((cursor--)) || true ;;
    s | S) ((cursor++)) || true ;;
    "" | $'\r' | $'\n') break ;;
    " ")
      if [ "${selected[$cursor]}" -eq 1 ]; then
        selected[$cursor]=0
      else
        selected[$cursor]=1
      fi
      ;;
  esac
  if [ "$cursor" -lt 0 ]; then cursor=$((${#interfaces[@]} - 1)); fi
  if [ "$cursor" -ge ${#interfaces[@]} ]; then cursor=0; fi
done

to_enable=()
to_disable=()
for i in "${!interfaces[@]}"; do
  if [ "${selected[$i]}" -eq 1 ]; then
    to_enable+=("${interfaces[$i]}")
  else
    to_disable+=("${interfaces[$i]}")
  fi
done

if [ ${#to_enable[@]} -eq 0 ]; then
  echo -e "\n⚠️  No interfaces selected. Removing service..."
  systemctl disable wol.service --now &>/dev/null || true
  rm -f /etc/systemd/system/wol.service
  systemctl daemon-reload
else
  cat <<EOF > /etc/systemd/system/wol.service
[Unit]
Description=Enable Wake-on-LAN persistently
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/bin/true
EOF

  echo -e "\nApplying changes:"
  for iface in "${to_enable[@]}"; do
    if ! valid_iface "$iface"; then
      echo "❌ Skipping invalid interface name: $iface"
      continue
    fi
    echo " [+] Enabling WoL on: $iface"
    printf 'ExecStartPre=%s -s %s wol g\n' "$ETHTOOL" "$iface" >> /etc/systemd/system/wol.service
    "$ETHTOOL" -s "$iface" wol g &>/dev/null
  done

  cat <<EOF >> /etc/systemd/system/wol.service

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable wol.service --now &>/dev/null
fi

for iface in "${to_disable[@]}"; do
  if is_wol_enabled "$iface"; then
    echo " [-] Disabling WoL on: $iface"
    "$ETHTOOL" -s "$iface" wol d &>/dev/null
  fi
done

echo -e "\n✅ All changes applied successfully!"
