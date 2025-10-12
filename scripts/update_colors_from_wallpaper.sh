#!/bin/bash

# Get current wallpaper from swww (primary method for your setup)
WALLPAPER=$(swww query 2>/dev/null | grep -oP 'image: \K.*' | head -1)

# Fallback to hyprpaper if swww not available
if [ -z "$WALLPAPER" ]; then
    WALLPAPER=$(hyprctl hyprpaper listloaded 2>/dev/null | head -1)
fi

# Exit gracefully if no wallpaper found
if [ -z "$WALLPAPER" ] || [ ! -f "$WALLPAPER" ]; then
    echo "No wallpaper found from swww or hyprpaper"
    exit 1
fi

# Extract colors using ImageMagick
if ! command -v convert &> /dev/null; then
    echo "ImageMagick not installed"
    exit 1
fi

# Extract 10 dominant colors, with better color detection
COLORS=$(magick "$WALLPAPER" -resize 100x100 -colors 10 -unique-colors txt:- 2>/dev/null | grep -oE '#[0-9A-F]{6}' | head -10)

# If magick didn't work, try convert
if [ -z "$COLORS" ]; then
    COLORS=$(convert "$WALLPAPER" -resize 100x100 -colors 10 -unique-colors txt:- 2>/dev/null | grep -oE '#[0-9A-F]{6}' | head -10)
fi

# Convert to array
IFS=$'\n' read -d '' -r -a COLOR_ARRAY <<< "$COLORS"

# Pick colors intelligently - find darker ones for bg, brighter for accents
BG_COLOR="${COLOR_ARRAY[0]:-#231419}"
# Look for brighter colors in the latter half
ACCENT1="${COLOR_ARRAY[3]:-#ff5570}"
ACCENT2="${COLOR_ARRAY[5]:-#ff8866}"
ACCENT3="${COLOR_ARRAY[6]:-#dd6688}"
ACCENT4="${COLOR_ARRAY[7]:-#ffaa55}"

# Extract RGB values from hex color (format: #RRGGBB)
# Remove the # and convert hex to decimal
BG_R=$((16#${BG_COLOR:1:2}))
BG_G=$((16#${BG_COLOR:3:2}))
BG_B=$((16#${BG_COLOR:5:2}))

# Update the SCSS file
SCSS_FILE="$HOME/.config/eww/eww.scss"
BACKUP_FILE="$HOME/.config/eww/eww.scss.backup"

# Backup original
cp "$SCSS_FILE" "$BACKUP_FILE"

# Update the color variables using sed
sed -i "s|\$bg-primary:.*|\$bg-primary: rgba(${BG_R}, ${BG_G}, ${BG_B}, 0.65);|" "$SCSS_FILE"
sed -i "s|\$accent-primary:.*|\$accent-primary: ${ACCENT1};|" "$SCSS_FILE"
sed -i "s|\$accent-secondary:.*|\$accent-secondary: ${ACCENT2};|" "$SCSS_FILE"
sed -i "s|\$accent-purple:.*|\$accent-purple: ${ACCENT3};|" "$SCSS_FILE"
sed -i "s|\$accent-yellow:.*|\$accent-yellow: ${ACCENT4};|" "$SCSS_FILE"

# Reload eww
eww reload

echo "Colors updated from wallpaper: $(basename "$WALLPAPER")"
