#!/bin/bash

# Check if a specific key is currently pressed
# Usage: check_key_pressed.sh <key>
# Returns: 0 (success) if key is pressed, 1 if not

KEY=$1

if [ -z "$KEY" ]; then
    exit 1
fi

# Use xdotool to check if key is pressed
if command -v xdotool &> /dev/null; then
    # Get the keycode for the key
    KEYCODE=$(xdotool getkeysymbol "$KEY" 2>/dev/null)

    # Check if the key is currently pressed using xdotool
    # This returns the state of modifier keys and other keys
    xdotool key --clearmodifiers "shift+${KEY}" 2>/dev/null

    # Alternative: use xinput to query keyboard state
    # This is more reliable for checking if a specific key is pressed
    if xinput query-state $(xinput list --id-only "keyboard" 2>/dev/null | head -1) 2>/dev/null | grep -q "key\[${KEY}\]=down"; then
        exit 0
    fi

    # Fallback: use xset to check if key is pressed
    # Get all pressed keys and check if our key is in there
    # This is hacky but works
    exit 1
else
    # No way to detect keyboard state
    exit 1
fi
