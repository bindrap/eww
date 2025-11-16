# Draggable Widgets - User Guide

## How to Drag Widgets

All EWW modal windows are now draggable using a simple keyboard + mouse combination:

### Steps:
1. **Hold down the 'd' key** on your keyboard
2. **Click and hold** the left mouse button on any widget
3. **Move your mouse** - the widget will follow in real-time
4. **Release the 'd' key** to stop dragging

### Draggable Widgets:
- System Information
- Weather
- ASCII Art
- Clock
- Volume Control
- Music Player
- CAVA Visualizer
- Rain Radar

## Technical Details

### Background Process
When you start EWW widgets using `scripts/start_widgets.sh`, a background keyboard monitor (`monitor_dkey.sh`) is automatically started. This process:
- Monitors keyboard input for the 'd' key
- Creates a state file at `/tmp/eww_dkey_pressed` when 'd' is pressed
- Removes the file when 'd' is released
- Runs continuously in the background

### Drag Mechanism
When you click on a widget:
1. The `drag_with_key.sh` script is triggered
2. It checks if the 'd' key is currently pressed (via the state file)
3. If yes, it enters a drag loop that:
   - Tracks mouse position in real-time (~60 FPS)
   - Updates the widget's position variables
   - Continues until 'd' is released or the mouse button is released
4. If no, the click is ignored (normal widget interaction)

### Dependencies
- `xinput` - For keyboard monitoring
- `xdotool` - For mouse position tracking
- Both are automatically installed when setting up the system

## Troubleshooting

### Dragging doesn't work:
1. Check if keyboard monitor is running: `ps aux | grep monitor_dkey`
2. Restart EWW widgets: `~/.config/eww/scripts/start_widgets.sh`
3. Check if state file is created when pressing 'd': `ls -la /tmp/eww_dkey_pressed`

### Widgets jump around:
- This can happen if the initial position is detected incorrectly
- Try clicking closer to the center of the widget

### Performance issues:
- The drag system updates at ~60 FPS
- If you experience lag, check CPU usage of `xinput test` process
