#!/bin/bash

# Example window to check
WIDGET="power_widget"

# Check if widget is currently open
if eww windows | grep -q "$WIDGET"; then
  ~/.config/eww/scripts/stop_widgets.sh
else
  ~/.config/eww/scripts/start_widgets.sh
fi
