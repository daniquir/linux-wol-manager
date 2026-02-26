#!/bin/bash

# Check for root privileges
if [ "$EUID" -ne 0 ]; then 
  echo "❌ Error: Please run this script as root (sudo)."
  exit 1
fi

# Check if ethtool is installed
if ! command -v ethtool &> /dev/null; then
    echo "📦 'ethtool' is not installed."
    read -p "Do you want to install it now? (y/n): " confirm
    if [[ $confirm == [yY] ]]; then
        apt update && apt install ethtool -y
    else
        echo "Exiting: ethtool is required."
        exit 1
    fi
fi

# 1. Get real physical interfaces
interfaces=($(ls /sys/class/net | grep -vE "lo|docker|vbox|virbr|veth|br-"))

if [ ${#interfaces[@]} -eq 0 ]; then
    echo "No compatible network interfaces found."
    exit 1
fi

# Variables for the interactive menu
selected=()
current_status=()

# Robust state detection
for i in "${!interfaces[@]}"; do
    if ethtool "${interfaces[$i]}" 2>/dev/null | grep -q "Wake-on: g"; then
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
        if [ $i -eq $cursor ]; then
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

# Interaction loop
while true; do
    draw_menu
    IFS= read -rsn1 key
    case "$key" in
        $'\x1b') 
            read -rsn2 -t 0.1 key
            case "$key" in
                "[A") ((cursor--)) ;; 
                "[B") ((cursor++)) ;; 
            esac
            ;;
        w|W) ((cursor--)) ;;
        s|S) ((cursor++)) ;;
        "") break ;;
        " ") 
            if [ "${selected[$cursor]}" -eq 1 ]; then
                selected[$cursor]=0
            else
                selected[$cursor]=1
            fi
            ;;
    esac
    if [ $cursor -lt 0 ]; then cursor=$((${#interfaces[@]} - 1)); fi
    if [ $cursor -ge ${#interfaces[@]} ]; then cursor=0; fi
done

# Prepare and Apply
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
    systemctl disable wol.service --now &>/dev/null
    rm -f /etc/systemd/system/wol.service
    systemctl daemon-reload
else
    cat <<EOF > /etc/systemd/system/wol.service
[Unit]
Description=Enable Wake-on-LAN persistently
After=network-online.target

[Service]
Type=oneshot
ExecStart=/bin/true
EOF

    echo -e "\nApplying changes:"
    for iface in "${to_enable[@]}"; do
        echo " [+] Enabling WoL on: $iface"
        echo "ExecStartPre=/sbin/ethtool -s $iface wol g" >> /etc/systemd/system/wol.service
        /sbin/ethtool -s "$iface" wol g &>/dev/null
    done

    cat <<EOF >> /etc/systemd/system/wol.service

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable wol.service --now &>/dev/null
fi

for iface in "${to_disable[@]}"; do
    if ethtool "$iface" 2>/dev/null | grep -q "Wake-on: g"; then
        echo " [-] Disabling WoL on: $iface"
        /sbin/ethtool -s "$iface" wol d &>/dev/null
    fi
done

echo -e "\n✅ All changes applied successfully!"
