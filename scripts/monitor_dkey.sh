#!/bin/bash

# Background keyboard monitor for 'd' key
# Creates a flag file when 'd' is pressed, removes it when released

STATE_FILE="/tmp/eww_dkey_pressed"

# Clean up on exit
cleanup() {
    rm -f "$STATE_FILE"
    exit 0
}

trap cleanup INT TERM EXIT

# Find keyboard device
if ! command -v xinput &> /dev/null; then
    echo "Error: xinput not found"
    exit 1
fi

# Get keyboard device ID
KEYBOARD_ID=$(xinput list | grep -i "keyboard" | grep -v "button" | head -1 | grep -oP 'id=\K\d+')

if [ -z "$KEYBOARD_ID" ]; then
    echo "Error: Could not find keyboard device"
    exit 1
fi

echo "Monitoring keyboard for 'd' key (Device ID: $KEYBOARD_ID)"

# Monitor keyboard events
# Key 40 is the 'd' key on most keyboards
xinput test "$KEYBOARD_ID" | while read -r line; do
    # Check for key press/release events
    if echo "$line" | grep -q "key press.*40"; then
        # 'd' key pressed
        touch "$STATE_FILE"
    elif echo "$line" | grep -q "key release.*40"; then
        # 'd' key released
        rm -f "$STATE_FILE"
    fi
done
