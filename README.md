# EWW Dynamic Widgets Configuration

A beautiful, dynamic widget setup for EWW (Elkowar's Wacky Widgets) that automatically adapts its color scheme to your wallpaper.

## Features

### 🎨 Dynamic Wallpaper-Based Theming
- **Automatic Color Extraction**: Colors are automatically extracted from your current wallpaper using ImageMagick
- **Live Updates**: Wallpaper watcher monitors changes and updates the theme in real-time using inotify
- **Intelligent Color Selection**: Picks darker tones for backgrounds and brighter tones for accents
- **Transparent Design**: Widgets use 65% opacity to blend beautifully with wallpaper

### 📊 System Information Widget
- **Collapsible Design**: Compact header that expands on hover
- **Real-time Monitoring**:
  - CPU usage with temperature
  - RAM usage with detailed breakdown
  - Disk usage
  - Network transfer rates (up/down)
  - Battery status (if available)
- **Color-Coded Indicators**:
  - Green: Normal (< 60%)
  - Yellow/Orange: Warning (60-80%)
  - Red: Critical (> 80%)
- **Hover Details**: Additional information revealed on hover for each metric

### ⚡ Power Menu
- **Compact Design**: Single power button on left side of screen
- **Hover-to-Expand**: Shows Reboot, Logout, and Lock options on hover
- **Smooth Animations**: Slide-out transition when hovering
- **Always Visible**: Stays on desktop layer, won't cover windows

### 🎵 Additional Widgets
- **CAVA Music Visualizer**: Real-time audio visualizer with auto-hide
  - Appears in center of screen when music is playing
  - Uses Unicode block characters for smooth 60 FPS animation
  - Automatically hides when audio stops
  - Works with Spotify, ncmpcpp, YouTube, and all PipeWire/PulseAudio sources
- **Weather Widget**: Displays weather information for Windsor
- **ASCII Art Display**: Random ASCII art with purple glow effect
- **Rain Radar**: Visual rain radar for Windsor
- **Music Player**: Controls for MPD/ncmpcpp
- **Volume Control**: Visual volume slider
- **Workspace Indicator**: Hyprland workspace switcher
- **Clock**: Time and date display
- **App Launcher**: Quick access to favorite applications

## File Structure

```
~/.config/eww/
├── eww.yuck              # Widget definitions and layout
├── eww.scss              # Styling with dynamic color variables
├── eww.scss.backup       # Backup of SCSS (auto-created)
├── README.md             # This file
└── scripts/
    ├── sysinfo2.sh                      # System information collector
    ├── weather.sh                       # Weather data fetcher
    ├── random_ascii.sh                  # ASCII art generator
    ├── update_colors_from_wallpaper.sh  # Color extraction and SCSS updater
    ├── watch_wallpaper.sh               # Polling-based wallpaper watcher
    ├── watch_wallpaper_inotify.sh       # Inotify-based wallpaper watcher (faster)
    ├── get_wallpaper_colors.sh          # Color polling script for widgets
    ├── cava_visualizer.sh               # CAVA output formatter for EWW
    └── is_audio_playing.sh              # Audio activity detection for visualizer

~/.config/cava/
└── config                               # CAVA configuration (60 FPS, 32 bars)
```

## Installation & Setup

### Prerequisites

```bash
# Install required dependencies
sudo pacman -S eww imagemagick inotify-tools cava  # Arch Linux
```

### Configuration

1. **Start EWW Widgets**:
   ```bash
   eww open sysinfo-window
   eww open power_widget
   # Add other windows as desired
   ```

2. **Enable Automatic Wallpaper Color Updates**:

   Add to `~/.config/hypr/hyprland.conf`:
   ```bash
   exec-once = ~/.config/eww/scripts/watch_wallpaper_inotify.sh &
   ```

   Or run manually in background:
   ```bash
   ~/.config/eww/scripts/watch_wallpaper_inotify.sh &
   ```

3. **Manual Color Update**:
   ```bash
   ~/.config/eww/scripts/update_colors_from_wallpaper.sh
   ```

## Widget Windows

### Active Windows

| Window | Location | Size | Description |
|--------|----------|------|-------------|
| `sysinfo-window` | Top-left (5, 5) | 250x200 | System information with hover expand |
| `power_widget` | Left (10, 500) | 80x65 | Compact power menu with hover expand |
| `weather-window` | Top-right (950, 20) | 350x250 | Weather information |
| `ascii-window` | Right (1026, 70) | 250x500 | ASCII art display |
| `file-button-window` | Left (10, 10) | 70x450 | App launcher buttons |
| `radar-window` | Bottom-right (880, 480) | 320x350 | Rain radar |
| `clock-window` | Top-right (1605, 10) | 300x80 | Clock display |
| `volume-window` | Top-left (95, 10) | 220x70 | Volume control |
| `music-window` | Top (325, 10) | 280x120 | Music player controls |
| `workspace-window` | Bottom (820, 1000) | 280x55 | Workspace indicator |
| `cava-window` | Center (35%, 45%) | 30%x120 | CAVA music visualizer (auto-hide) |

## How Dynamic Colors Work

### Color Extraction Process

1. **Wallpaper Detection**:
   - Primary: Checks `swww` for current wallpaper (most reliable)
   - Fallback: Checks `hyprpaper` if swww not available
   - Works with any wallpaper set via swww or hyprpaper

2. **Color Analysis**:
   - Resizes image to 100x100 for faster processing
   - Extracts 10 dominant colors using ImageMagick
   - Selects colors intelligently:
     - First color → Background (darkest)
     - Colors 3, 5, 6, 7 → Accents (brighter tones)

3. **SCSS Update**:
   - Converts hex colors to RGB
   - Updates SCSS variables dynamically:
     - `$bg-primary`: rgba(R, G, B, 0.65) - 65% transparency
     - `$accent-primary`, `$accent-secondary`, `$accent-purple`, `$accent-yellow`
   - Creates automatic backup (eww.scss.backup)
   - Reloads EWW to apply changes instantly

### Color Variables

The following SCSS variables are automatically updated:

```scss
$bg-primary:       // Main background color (from wallpaper)
$accent-primary:   // Primary accent color
$accent-secondary: // Secondary accent color
$accent-purple:    // Purple accent
$accent-yellow:    // Yellow accent
```

Static colors (not changed by wallpaper):
```scss
$accent-green:  #88dd77  // Always green for "good" indicators
$accent-red:    #ff4455  // Always red for warnings/errors
$accent-blue:   #6699ff  // Cool blue for contrast
```

## Customization

### Changing Widget Positions

Edit `eww.yuck` and modify the `:geometry` property of any window:

```lisp
(defwindow sysinfo-window
  :geometry (geometry :x 5 :y 5 :width 250 :height 200)
  ...
)
```

### Adjusting Update Intervals

Edit `eww.yuck` poll intervals:

```lisp
(defpoll sysinfo :interval "3s" ...)        # System info every 3 seconds
(defpoll weather :interval "600s" ...)      # Weather every 10 minutes
(defpoll ascii :interval "120s" ...)        # ASCII art every 2 minutes
```

### Modifying Wallpaper Watcher

The configuration now uses `watch_wallpaper_inotify.sh` which detects changes instantly using inotify instead of polling. This is more efficient and responds immediately to wallpaper changes.

If you prefer the polling method, edit `watch_wallpaper.sh` and change the sleep interval:

```bash
sleep 10  # Check every 10 seconds (change as needed)
```

## Keyboard Shortcuts & Actions

### Power Menu Actions

The power menu appears on the left side (at y:500px). Hover over the main power icon to reveal options:

- **Reboot**: `systemctl reboot` - Red icon
- **Logout**: `hyprctl dispatch exit` - Blue icon
- **Lock**: `loginctl lock-session` - Purple icon

### App Launcher

- File Manager → Opens `~` in default file manager
- Chrome → Opens Google Chrome
- Prism Launcher → Minecraft launcher
- Steam → Steam client
- Spotify → Spotify client
- Discord → Discord client
- Music Player → ncmpcpp in kitty terminal

## Troubleshooting

### Colors Not Updating

1. **Check All Dependencies**:
   ```bash
   which magick inotifywait swww
   ```

2. **Check Wallpaper Watcher is Running**:
   ```bash
   ps aux | grep watch_wallpaper_inotify
   ```

3. **Check Wallpaper Detection**:
   ```bash
   swww query
   # or
   hyprctl hyprpaper listloaded
   ```

4. **Run Manual Update**:
   ```bash
   ~/.config/eww/scripts/update_colors_from_wallpaper.sh
   ```

5. **Restart Watcher if Needed**:
   ```bash
   pkill -f watch_wallpaper_inotify
   ~/.config/eww/scripts/watch_wallpaper_inotify.sh &
   ```

### Widgets Not Showing

1. **Check EWW is Running**:
   ```bash
   eww ping
   ```

2. **Check EWW Logs**:
   ```bash
   eww logs
   ```

3. **Reload EWW**:
   ```bash
   eww reload
   ```

### System Info Not Showing

Ensure `sysinfo2.sh` script exists and is executable:
```bash
chmod +x ~/.config/eww/scripts/sysinfo2.sh
```

## Performance Notes

- **CPU Usage**: Minimal (~1-2% when active)
- **Memory Usage**: ~50-100MB for all widgets
- **Wallpaper Watcher**: Uses inotify for instant detection (no polling overhead)
- **Color Extraction**: Takes 1-2 seconds per wallpaper change
- **Transparency**: 65% opacity for better wallpaper visibility and reduced visual clutter

## Adding to Hyprland Startup

Add to `~/.config/hypr/hyprland.conf`:

```bash
# Start EWW widgets
exec-once = eww daemon
exec-once = eww open sysinfo-window
exec-once = eww open power_widget
exec-once = eww open cava-window
exec-once = ~/.config/eww/scripts/watch_wallpaper_inotify.sh &

# Add other windows as desired
exec-once = eww open clock-window
exec-once = eww open volume-window
exec-once = eww open workspace-window
```

## Credits

- **EWW**: [Elkowar's Wacky Widgets](https://github.com/elkowar/eww)
- **Color Scheme**: Dynamically generated from wallpaper
- **Icons**: Nerd Fonts (JetBrainsMono, CaskaydiaCove)

## License

Feel free to modify and share this configuration as you wish!

---

## Recent Updates (2025-10-09)

### Latest Changes
- ✅ **NEW: CAVA Music Visualizer**: Real-time audio visualizer with auto-hide
  - Appears in center of screen when music is playing
  - 60 FPS smooth animation with Unicode block characters
  - Automatically hides when no audio is detected
  - Works with all PipeWire/PulseAudio sources (Spotify, ncmpcpp, YouTube, etc.)
  - PipeWire-compatible audio detection
- ✅ **Fixed inotify dependency**: Added `inotify-tools` package requirement
- ✅ **Fixed RGB hex conversion**: Corrected color parsing bug in update script
- ✅ **Removed hardcoded paths**: Made wallpaper detection fully dynamic
- ✅ **Optimized wallpaper detection**: Now uses `swww` as primary method
- ✅ **Fixed inline style conflicts**: Removed CSS override to allow SCSS colors to work
- ✅ **Instant color updates**: Watcher responds immediately to wallpaper changes
- ✅ **Zero CPU overhead**: Event-driven updates via inotify (not polling)
- ✅ **Automatic startup**: Integrated into Hyprland config, starts on login

### Previous Updates
- ✅ Added transparent design (65% opacity) for better wallpaper integration
- ✅ Implemented inotify-based wallpaper watcher for instant color updates
- ✅ Fixed power menu visibility issues (now at left side, y:500px)
- ✅ Power menu stays on desktop layer, won't cover windows
- ✅ Automatic SCSS backup on color updates
- ✅ Integrated wallpaper watcher into Hyprland startup

---

**Last Updated**: 2025-10-09
**EWW Version**: Compatible with EWW v0.4.0+

## How It Works

The dynamic color system is fully automatic:

1. **On Startup**: `watch_wallpaper_inotify.sh` starts via Hyprland's `exec-once`
2. **On Wallpaper Change**: Script detects change instantly via inotify
3. **Color Extraction**: ImageMagick analyzes wallpaper and extracts dominant colors
4. **SCSS Update**: Color variables are updated automatically
5. **EWW Reload**: Widgets reload with new colors instantly
6. **Zero Intervention**: Everything happens automatically in the background

**Result**: Your widgets always match your wallpaper, with zero manual effort!
