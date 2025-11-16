#!/bin/bash

# Start EWW widgets for Hyprland
EWW_CONFIG_DIR="$HOME/.config/eww"

# Kill existing EWW processes
killall eww 2>/dev/null || true

# Wait a moment
sleep 1

# Start EWW daemon
eww daemon &
sleep 2

# Check if wallpaper color watcher is already running
if ! pgrep -f "watch_wallpaper" > /dev/null; then
    echo "Starting wallpaper color watcher..."
    "$EWW_CONFIG_DIR/scripts/watch_wallpaper_inotify.sh" > /dev/null 2>&1 &
    WATCHER_PID=$!
    echo "Wallpaper color watcher started (PID: $WATCHER_PID)"
else
    echo "Wallpaper color watcher already running"
fi

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
