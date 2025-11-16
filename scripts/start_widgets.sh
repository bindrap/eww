#!/bin/bash

# Start EWW widgets for Hyprland
EWW_CONFIG_DIR="$HOME/.config/eww"

# Kill existing EWW processes
killall eww 2>/dev/null || true

# Kill existing keyboard monitor
pkill -f monitor_dkey.sh 2>/dev/null || true

# Wait a moment
sleep 1

# Start keyboard monitor in background for drag functionality
# This monitors the 'd' key for drag-and-drop
"$EWW_CONFIG_DIR/scripts/monitor_dkey.sh" &
MONITOR_PID=$!
echo "Keyboard monitor started (PID: $MONITOR_PID)"

# Start EWW daemon
eww daemon &
sleep 2

# Open widgets
eww open sysinfo-window
#eww open weather-window
eww open ascii-window
#eww open file-button-window
#eww open youtube-window
#eww open radar-window
eww open power_widget
#eww open clock-window
eww open workspace-window

echo "EWW widgets started!"
