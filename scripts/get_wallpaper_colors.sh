#!/bin/bash

# Get current wallpaper from swww (primary method)
WALLPAPER=$(swww query 2>/dev/null | grep -oP 'image: \K.*' | head -1)

# Fallback to hyprpaper if swww not available
if [ -z "$WALLPAPER" ]; then
    WALLPAPER=$(hyprctl hyprpaper listloaded 2>/dev/null | head -1)
fi

# Exit with fallback style if no wallpaper found
if [ -z "$WALLPAPER" ] || [ ! -f "$WALLPAPER" ]; then
    echo "background: rgba(38, 30, 50, 0.85) !important; border: 1px solid rgba(255, 107, 138, 0.25) !important;"
    exit 0
fi

# Extract dominant colors using ImageMagick
if command -v magick &> /dev/null && [ -f "$WALLPAPER" ]; then
    # Get palette of 10 colors for more variety and better color selection
    COLORS=$(magick "$WALLPAPER" -resize 150x150 -colors 10 -unique-colors txt:- 2>/dev/null | grep -oE '#[0-9A-F]{6}' | head -10)

    # Parse colors into an array
    IFS=$'\n' read -d '' -r -a COLOR_ARRAY <<< "$COLORS"

    # Select colors intelligently - pick darker ones for bg, brighter for accents
    # Try to get more vibrant colors from the middle/end of the palette
    BG_COLOR="${COLOR_ARRAY[0]:-#3e2e50}"
    ACCENT1="${COLOR_ARRAY[3]:-#ff6b8a}"
    ACCENT2="${COLOR_ARRAY[5]:-#89b4fa}"
    ACCENT3="${COLOR_ARRAY[7]:-#c084fc}"
    ACCENT4="${COLOR_ARRAY[8]:-#ffd580}"

    # Convert hex to decimal RGB values for background
    BG_R=$((16#${BG_COLOR:1:2}))
    BG_G=$((16#${BG_COLOR:3:2}))
    BG_B=$((16#${BG_COLOR:5:2}))

    # Convert accent1 to decimal RGB for border
    A1_R=$((16#${ACCENT1:1:2}))
    A1_G=$((16#${ACCENT1:3:2}))
    A1_B=$((16#${ACCENT1:5:2}))

    # Output as inline CSS - just background for now, as eww doesn't handle multiple properties well
    echo "background: rgba(${BG_R}, ${BG_G}, ${BG_B}, 0.75); border-color: rgba(${A1_R}, ${A1_G}, ${A1_B}, 0.5);"
else
    # Fallback style
    echo "background: rgba(38, 30, 50, 0.85); border-color: rgba(255, 107, 138, 0.35);"
fi
