#!/bin/bash

# Draggable window script for EWW
# Usage: drag_window.sh <window_var_prefix>
# Example: drag_window.sh music (for music_x and music_y variables)

WINDOW_PREFIX=$1

if [ -z "$WINDOW_PREFIX" ]; then
    echo "Usage: drag_window.sh <window_var_prefix>"
    exit 1
fi

# State file to track dragging
STATE_FILE="/tmp/eww_drag_${WINDOW_PREFIX}"
echo "1" > "$STATE_FILE"

# Function to get mouse position
get_mouse_pos() {
    if command -v slurp &> /dev/null; then
        slurp -p -f "%x %y" 2>/dev/null
    elif command -v xdotool &> /dev/null; then
        MOUSE_INFO=$(xdotool getmouselocation --shell)
        X=$(echo "$MOUSE_INFO" | grep "^X=" | cut -d= -f2)
        Y=$(echo "$MOUSE_INFO" | grep "^Y=" | cut -d= -f2)
        echo "$X $Y"
    else
        echo "0 0"
    fi
}

# Get initial mouse position
read -r START_X START_Y <<< $(get_mouse_pos)

# Get initial window position from EWW variables
INITIAL_WIN_X=$(eww get "${WINDOW_PREFIX}_x" 2>/dev/null || echo "100")
INITIAL_WIN_Y=$(eww get "${WINDOW_PREFIX}_y" 2>/dev/null || echo "100")

# Drag loop - runs while state file exists and contains "1"
while [ -f "$STATE_FILE" ] && [ "$(cat $STATE_FILE)" = "1" ]; do
    # Get current mouse position
    read -r CURRENT_X CURRENT_Y <<< $(get_mouse_pos)

    # Calculate offset from starting position
    OFFSET_X=$((CURRENT_X - START_X))
    OFFSET_Y=$((CURRENT_Y - START_Y))

    # Calculate new window position
    NEW_X=$((INITIAL_WIN_X + OFFSET_X))
    NEW_Y=$((INITIAL_WIN_Y + OFFSET_Y))

    # Update window position
    eww update "${WINDOW_PREFIX}_x=${NEW_X}"
    eww update "${WINDOW_PREFIX}_y=${NEW_Y}"

    # Small delay to avoid excessive CPU usage
    sleep 0.016  # ~60 FPS
done

# Cleanup
rm -f "$STATE_FILE"
