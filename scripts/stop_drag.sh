#!/bin/bash

# Stop dragging a window
# Usage: stop_drag.sh <window_var_prefix>

WINDOW_PREFIX=$1

if [ -z "$WINDOW_PREFIX" ]; then
    echo "Usage: stop_drag.sh <window_var_prefix>"
    exit 1
fi

STATE_FILE="/tmp/eww_drag_${WINDOW_PREFIX}"

# Signal the drag script to stop by writing 0 to state file
if [ -f "$STATE_FILE" ]; then
    echo "0" > "$STATE_FILE"
fi
