#!/bin/bash

# Watch for wallpaper changes and update colors automatically

LAST_WALLPAPER=""
UPDATE_SCRIPT="$HOME/.config/eww/scripts/update_colors_from_wallpaper.sh"

while true; do
    # Get current wallpaper
    CURRENT=$(hyprctl hyprpaper listloaded 2>/dev/null | head -1)

    if [ -z "$CURRENT" ]; then
        CURRENT=$(swww query 2>/dev/null | grep -oP 'image: \K.*' | head -1)
    fi

    # If wallpaper changed, update colors
    if [ -n "$CURRENT" ] && [ "$CURRENT" != "$LAST_WALLPAPER" ]; then
        echo "Wallpaper changed to: $CURRENT"
        LAST_WALLPAPER="$CURRENT"

        # Wait a moment for the wallpaper to fully load
        sleep 1

        # Update colors
        "$UPDATE_SCRIPT"
    fi

    # Check every 10 seconds
    sleep 10
done
