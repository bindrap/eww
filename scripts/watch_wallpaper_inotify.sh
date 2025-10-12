#!/bin/bash

# Watch for wallpaper changes using inotify on swww cache
# This is more efficient than polling

UPDATE_SCRIPT="$HOME/.config/eww/scripts/update_colors_from_wallpaper.sh"

# If using swww, watch the cache directory
SWWW_CACHE="$HOME/.cache/swww"

if [ -d "$SWWW_CACHE" ]; then
    echo "Watching swww cache for wallpaper changes..."
    inotifywait -m -e modify,create "$SWWW_CACHE" |
    while read -r directory events filename; do
        echo "Wallpaper changed, updating colors..."
        sleep 1  # Give swww time to finish writing
        "$UPDATE_SCRIPT"
    done
else
    # Fallback to hyprpaper socket watching
    echo "swww not found, using polling method..."
    exec "$HOME/.config/eww/scripts/watch_wallpaper.sh"
fi
