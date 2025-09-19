#!/bin/bash


# Emoji headers
USER_ICON="👤"
HOST_ICON="💻"
UPTIME_ICON="⏱️"
MEM_ICON="🧠"
DISK_ICON="💾"
CPU_ICON="🧮"
KERNEL_ICON="📦"
WM_ICON="🖥️"
SHELL_ICON="🐚"
NET_ICON="🌐"

# User info
USER=$(whoami)
HOST=$(hostname)
UPTIME=$(uptime -p)
KERNEL=$(uname -r)
WM="Hyprland"
SHELL_NAME="${SHELL##*/}"

# Memory usage
MEM_RAW=$(free | awk '/Mem:/ {print $3/$2 * 100.0}')
MEM_PCT=$(printf "%.0f" "$MEM_RAW")
MEM_BAR=$(printf "[%-20s]" "$(head -c $((MEM_PCT / 5)) < /dev/zero | tr '\0' '=')")

# Disk usage
DISK_USED=$(df -h / | awk 'NR==2 {print $3}')
DISK_TOTAL=$(df -h / | awk 'NR==2 {print $2}')
DISK_PCT=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
DISK_BAR=$(printf "[%-20s]" "$(head -c $((DISK_PCT / 5)) < /dev/zero | tr '\0' '#')")

# CPU usage
CPU_PCT=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')
CPU_BAR=$(printf "[%-20s]" "$(head -c $((CPU_PCT / 5)) < /dev/zero | tr '\0' '#')")

# Network usage (basic)
INTERFACE=$(ip route get 1.1.1.1 | awk '{print $5}' | head -1)
RX_BYTES_BEFORE=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes)
TX_BYTES_BEFORE=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes)
sleep 0.5
RX_BYTES_AFTER=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes)
TX_BYTES_AFTER=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes)

RX_RATE=$(echo "scale=1; ($RX_BYTES_AFTER - $RX_BYTES_BEFORE) / 1024 / 0.5" | bc)
TX_RATE=$(echo "scale=1; ($TX_BYTES_AFTER - $TX_BYTES_BEFORE) / 1024 / 0.5" | bc)

# Output with fancy formatting
echo "$USER_ICON User:     $USER"
echo "$HOST_ICON Host:     $HOST"
echo "$UPTIME_ICON Uptime:   $UPTIME"
echo "$MEM_ICON Memory:   $MEM_PCT% $MEM_BAR"
echo "$DISK_ICON Disk:     $DISK_USED / $DISK_TOTAL $DISK_BAR"
echo "$CPU_ICON CPU:       ${CPU_PCT}% $CPU_BAR"
echo "$KERNEL_ICON Kernel:   $KERNEL"
echo "$WM_ICON WM:        $WM"
echo "$SHELL_ICON Shell:     $SHELL_NAME"
echo "$NET_ICON Network:  ⬇ $RX_RATE KB/s  ⬆ $TX_RATE KB/s"

