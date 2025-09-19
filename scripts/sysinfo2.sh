#!/bin/bash

# System Info Script for EWW Widget
# Outputs JSON/structured data for EWW consumption

# Function to get memory info
get_memory_info() {
    local mem_info=$(free -b)
    local mem_total=$(echo "$mem_info" | awk '/Mem:/ {print $2}')
    local mem_used=$(echo "$mem_info" | awk '/Mem:/ {print $3}')
    local mem_available=$(echo "$mem_info" | awk '/Mem:/ {print $7}')
    
    if command -v bc &> /dev/null; then
        local mem_pct=$(echo "scale=0; $mem_used * 100 / $mem_total" | bc)
        local mem_used_gb=$(echo "scale=1; $mem_used / 1024 / 1024 / 1024" | bc)
        local mem_total_gb=$(echo "scale=1; $mem_total / 1024 / 1024 / 1024" | bc)
    else
        local mem_pct=$((mem_used * 100 / mem_total))
        local mem_used_gb=$((mem_used / 1024 / 1024 / 1024))
        local mem_total_gb=$((mem_total / 1024 / 1024 / 1024))
    fi
    
    echo "$mem_pct|$mem_used_gb|$mem_total_gb"
}

# Function to get disk info
get_disk_info() {
    local disk_info=$(df -h / 2>/dev/null | awk 'NR==2 {print $3 " " $2 " " $5}')
    local disk_used=$(echo "$disk_info" | awk '{print $1}')
    local disk_total=$(echo "$disk_info" | awk '{print $2}')
    local disk_pct=$(echo "$disk_info" | awk '{print $3}' | tr -d '%')
    
    echo "$disk_pct|$disk_used|$disk_total"
}

# Function to get CPU info
get_cpu_info() {
    # Get CPU model
    local cpu_model=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs | cut -d' ' -f1-3)
    
    # Get CPU usage using a more reliable method
    local cpu_line=$(grep "cpu " /proc/stat)
    local cpu_times=($cpu_line)
    local idle1=${cpu_times[4]}
    local total1=0
    for time in "${cpu_times[@]:1}"; do
        total1=$((total1 + time))
    done
    
    sleep 0.1
    
    local cpu_line2=$(grep "cpu " /proc/stat)
    local cpu_times2=($cpu_line2)
    local idle2=${cpu_times2[4]}
    local total2=0
    for time in "${cpu_times2[@]:1}"; do
        total2=$((total2 + time))
    done
    
    local idle_delta=$((idle2 - idle1))
    local total_delta=$((total2 - total1))
    
    if [ $total_delta -gt 0 ]; then
        local cpu_pct=$((100 * (total_delta - idle_delta) / total_delta))
    else
        local cpu_pct=0
    fi
    
    echo "$cpu_pct|$cpu_model"
}

# Function to get network info
get_network_info() {
    local interface=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $5}' | head -1)
    
    if [[ -n "$interface" && -f "/sys/class/net/$interface/statistics/rx_bytes" ]]; then
        local rx_bytes=$(cat "/sys/class/net/$interface/statistics/rx_bytes" 2>/dev/null || echo "0")
        local tx_bytes=$(cat "/sys/class/net/$interface/statistics/tx_bytes" 2>/dev/null || echo "0")
        
        if command -v bc &> /dev/null; then
            local rx_mb=$(echo "scale=1; $rx_bytes / 1024 / 1024" | bc)
            local tx_mb=$(echo "scale=1; $tx_bytes / 1024 / 1024" | bc)
        else
            local rx_mb=$((rx_bytes / 1024 / 1024))
            local tx_mb=$((tx_bytes / 1024 / 1024))
        fi
        
        echo "$interface|$rx_mb|$tx_mb"
    else
        echo "none|0|0"
    fi
}

# Function to get uptime in a clean format
get_uptime() {
    local uptime_raw=$(cat /proc/uptime | cut -d. -f1)
    local days=$((uptime_raw / 86400))
    local hours=$(((uptime_raw % 86400) / 3600))
    local minutes=$(((uptime_raw % 3600) / 60))
    
    if [ $days -gt 0 ]; then
        echo "${days}d ${hours}h ${minutes}m"
    elif [ $hours -gt 0 ]; then
        echo "${hours}h ${minutes}m"
    else
        echo "${minutes}m"
    fi
}

# Function to get temperature (if available)
get_temperature() {
    local temp_file=""
    local temp_celsius=0
    
    # Try different temperature sources
    if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
        temp_file="/sys/class/thermal/thermal_zone0/temp"
    elif [ -f /sys/devices/platform/coretemp.0/hwmon/hwmon*/temp1_input ]; then
        temp_file=$(ls /sys/devices/platform/coretemp.0/hwmon/hwmon*/temp1_input 2>/dev/null | head -1)
    fi
    
    if [ -n "$temp_file" ]; then
        local temp_raw=$(cat "$temp_file" 2>/dev/null || echo "0")
        temp_celsius=$((temp_raw / 1000))
    fi
    
    echo "$temp_celsius"
}

# Function to get battery info (if available)
get_battery_info() {
    local battery_path="/sys/class/power_supply/BAT0"
    local battery_pct=0
    local battery_status="Unknown"
    
    if [ -d "$battery_path" ]; then
        battery_pct=$(cat "$battery_path/capacity" 2>/dev/null || echo "0")
        battery_status=$(cat "$battery_path/status" 2>/dev/null || echo "Unknown")
    fi
    
    echo "$battery_pct|$battery_status"
}

# Main output function
output_data() {
    local format="${1:-json}"
    
    # Gather all system info
    local user=$(whoami)
    local host=$(hostname)
    local uptime=$(get_uptime)
    local kernel=$(uname -r)
    local shell_name="${SHELL##*/}"
    
    # Get detailed info
    local mem_info=$(get_memory_info)
    local disk_info=$(get_disk_info)
    local cpu_info=$(get_cpu_info)
    local net_info=$(get_network_info)
    local temp=$(get_temperature)
    local battery_info=$(get_battery_info)
    
    # Parse the info
    local mem_pct=$(echo "$mem_info" | cut -d'|' -f1)
    local mem_used=$(echo "$mem_info" | cut -d'|' -f2)
    local mem_total=$(echo "$mem_info" | cut -d'|' -f3)
    
    local disk_pct=$(echo "$disk_info" | cut -d'|' -f1)
    local disk_used=$(echo "$disk_info" | cut -d'|' -f2)
    local disk_total=$(echo "$disk_info" | cut -d'|' -f3)
    
    local cpu_pct=$(echo "$cpu_info" | cut -d'|' -f1)
    local cpu_model=$(echo "$cpu_info" | cut -d'|' -f2)
    
    local net_interface=$(echo "$net_info" | cut -d'|' -f1)
    local net_rx=$(echo "$net_info" | cut -d'|' -f2)
    local net_tx=$(echo "$net_info" | cut -d'|' -f3)
    
    local battery_pct=$(echo "$battery_info" | cut -d'|' -f1)
    local battery_status=$(echo "$battery_info" | cut -d'|' -f2)
    
    case "$format" in
        json)
            cat << EOF
{
  "user": "$user",
  "host": "$host",
  "uptime": "$uptime",
  "kernel": "$kernel",
  "shell": "$shell_name",
  "wm": "Hyprland",
  "memory": {
    "percentage": $mem_pct,
    "used": "$mem_used",
    "total": "$mem_total"
  },
  "disk": {
    "percentage": $disk_pct,
    "used": "$disk_used",
    "total": "$disk_total"
  },
  "cpu": {
    "percentage": $cpu_pct,
    "model": "$cpu_model",
    "temperature": $temp
  },
  "network": {
    "interface": "$net_interface",
    "rx_mb": "$net_rx",
    "tx_mb": "$net_tx"
  },
  "battery": {
    "percentage": $battery_pct,
    "status": "$battery_status"
  }
}
EOF
            ;;
        simple)
            echo "user:$user"
            echo "host:$host"
            echo "uptime:$uptime"
            echo "kernel:$kernel"
            echo "shell:$shell_name"
            echo "wm:Hyprland"
            echo "mem_pct:$mem_pct"
            echo "mem_used:$mem_used"
            echo "mem_total:$mem_total"
            echo "disk_pct:$disk_pct"
            echo "disk_used:$disk_used"
            echo "disk_total:$disk_total"
            echo "cpu_pct:$cpu_pct"
            echo "cpu_model:$cpu_model"
            echo "cpu_temp:$temp"
            echo "net_interface:$net_interface"
            echo "net_rx:$net_rx"
            echo "net_tx:$net_tx"
            echo "battery_pct:$battery_pct"
            echo "battery_status:$battery_status"
            ;;
        eww)
            # EWW-specific format for easy parsing
            echo "(box :class \"sysinfo\""
            echo "  :orientation \"v\""
            echo "  (label :text \"󰀄 $user@$host\")"
            echo "  (label :text \"󰅐 $uptime\")"
            echo "  (label :text \"🧠 ${mem_pct}% (${mem_used}GB/${mem_total}GB)\")"
            echo "  (label :text \"💾 ${disk_pct}% (${disk_used}/${disk_total})\")"
            echo "  (label :text \"🔥 ${cpu_pct}% ${cpu_model}\")"
            echo "  (label :text \"🌐 ${net_interface} ↓${net_rx}MB ↑${net_tx}MB\")"
            if [ "$battery_pct" -gt 0 ]; then
                echo "  (label :text \"🔋 ${battery_pct}% ${battery_status}\")"
            fi
            echo ")"
            ;;
        bar)
            echo "(defvar cpu_percent $cpu_pct)"
            echo "(defvar mem_percent $mem_pct)"
            echo "(defvar disk_percent $disk_pct)"
            echo "(defvar temp_c $temp)"
            echo "(defvar battery_percent $battery_pct)"
            ;;
    esac
}

# Handle command line arguments
case "${1:-json}" in
    json|simple|eww|bar)
        output_data "$1"
        ;;
    --help|-h)
        echo "Usage: $0 [json|simple|eww]"
        echo "  json   - Output as JSON (default)"
        echo "  simple - Output as key:value pairs"
        echo "  eww    - Output as EWW widget format"
        ;;
    *)
        echo "Unknown format: $1"
        echo "Use: $0 [json|simple|eww]"
        exit 1
        ;;
esac