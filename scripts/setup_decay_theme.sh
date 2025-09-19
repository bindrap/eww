#!/bin/bash

# Decay Green Theme Setup Script for EWW Widgets
# For EndeavourOS with Hyde and Hyprland

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# EWW config directory
EWW_CONFIG_DIR="$HOME/.config/eww"
SCRIPTS_DIR="$EWW_CONFIG_DIR/scripts"
ASSETS_DIR="$EWW_CONFIG_DIR/assets"

echo -e "${GREEN}🌿 Setting up Decay Green Theme for EWW Widgets${NC}"
echo -e "${BLUE}=============================================${NC}"

# Create directories if they don't exist
echo -e "${YELLOW}📁 Creating directories...${NC}"
mkdir -p "$EWW_CONFIG_DIR"
mkdir -p "$SCRIPTS_DIR" 
mkdir -p "$ASSETS_DIR"

# Backup existing files
echo -e "${YELLOW}💾 Backing up existing configuration...${NC}"
if [ -f "$EWW_CONFIG_DIR/eww.yuck" ]; then
    cp "$EWW_CONFIG_DIR/eww.yuck" "$EWW_CONFIG_DIR/eww.yuck.backup.$(date +%Y%m%d_%H%M%S)"
    echo -e "${GREEN}✓ Backed up eww.yuck${NC}"
fi

if [ -f "$EWW_CONFIG_DIR/eww.scss" ]; then
    cp "$EWW_CONFIG_DIR/eww.scss" "$EWW_CONFIG_DIR/eww.scss.backup.$(date +%Y%m%d_%H%M%S)"
    echo -e "${GREEN}✓ Backed up eww.scss${NC}"
fi

# Check if scripts exist
echo -e "${YELLOW}🔍 Checking required scripts...${NC}"
SCRIPTS_NEEDED=("sysinfo2.sh" "weather.sh" "random_ascii.sh")
MISSING_SCRIPTS=()

for script in "${SCRIPTS_NEEDED[@]}"; do
    if [ ! -f "$SCRIPTS_DIR/$script" ]; then
        MISSING_SCRIPTS+=("$script")
    else
        chmod +x "$SCRIPTS_DIR/$script"
        echo -e "${GREEN}✓ Found $script${NC}"
    fi
done

if [ ${#MISSING_SCRIPTS[@]} -gt 0 ]; then
    echo -e "${RED}⚠️  Missing scripts:${NC}"
    for script in "${MISSING_SCRIPTS[@]}"; do
        echo -e "${RED}   - $script${NC}"
    done
    echo -e "${YELLOW}Please ensure these scripts are in $SCRIPTS_DIR${NC}"
fi

# Create a simple random ASCII art script if it doesn't exist
if [ ! -f "$SCRIPTS_DIR/random_ascii.sh" ]; then
    echo -e "${YELLOW}📝 Creating random_ascii.sh...${NC}"
    cat > "$SCRIPTS_DIR/random_ascii.sh" << 'EOF'
#!/bin/bash

# Simple ASCII art script for decay theme
ASCII_ART=(
'    ▄▄▄▄▄▄▄
   ██▀▀▀▀▀██
   ██  ◉  ██
   ██▄▄▄▄▄██
    ▀▀▀▀▀▀▀

  Decay Green'

'  ╔══════════════╗
  ║    Welcome   ║
  ║      to      ║
  ║   Hyprland   ║
  ╚══════════════╝'

'    🌿 Nature
   Computing 🌿

  ╭─────────────╮
  │  Eco-Friendly │
  │    Desktop    │
  ╰─────────────╯'

'     ░░░░░▄░░░░░░░░░
     ░░░░▄█░░░░░░░░░
     ░░░▄▀█▀█▄░░░░░░
     ░░▄█░░░░█▄░░░░░
     ░░█▀░░░░░▀█░░░░
      decay theme'
)

# Pick a random ASCII art
RANDOM_INDEX=$((RANDOM % ${#ASCII_ART[@]}))
echo "${ASCII_ART[$RANDOM_INDEX]}"
EOF
    chmod +x "$SCRIPTS_DIR/random_ascii.sh"
    echo -e "${GREEN}✓ Created random_ascii.sh${NC}"
fi

# Download sample radar image if it doesn't exist
if [ ! -f "$ASSETS_DIR/radar.png" ]; then
    echo -e "${YELLOW}🌧️  Creating sample radar image...${NC}"
    # Create a simple placeholder image using ImageMagick if available
    if command -v convert >/dev/null 2>&1; then
        convert -size 300x300 xc:'#1a1a1a' \
                -fill '#76946a' -draw 'circle 150,150 150,50' \
                -fill '#98bb6c' -draw 'circle 150,150 150,100' \
                -fill '#5a7a4f' -draw 'circle 150,150 150,150' \
                -font DejaVu-Sans -pointsize 20 -fill '#c5c9c5' \
                -gravity center -annotate +0+0 'RADAR\nPlaceholder' \
                "$ASSETS_DIR/radar.png"
        echo -e "${GREEN}✓ Created radar placeholder${NC}"
    else
        echo -e "${YELLOW}⚠️  ImageMagick not found. Please add your own radar.png to $ASSETS_DIR${NC}"
        # Create a simple text file as placeholder
        echo "Radar image placeholder - replace with actual radar.png" > "$ASSETS_DIR/radar_placeholder.txt"
    fi
fi

# Check dependencies
echo -e "${YELLOW}🔧 Checking dependencies...${NC}"
DEPS=("eww" "jq" "curl" "bc")
MISSING_DEPS=()

for dep in "${DEPS[@]}"; do
    if command -v "$dep" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ $dep${NC}"
    else
        MISSING_DEPS+=("$dep")
    fi
done

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo -e "${RED}⚠️  Missing dependencies:${NC}"
    for dep in "${MISSING_DEPS[@]}"; do
        echo -e "${RED}   - $dep${NC}"
    done
    echo -e "${YELLOW}Install with: paru -S ${MISSING_DEPS[*]} ${NC}"
fi

# Create Hyprland integration script
echo -e "${YELLOW}⚡ Creating Hyprland integration...${NC}"
cat > "$SCRIPTS_DIR/start_widgets.sh" << 'EOF'
#!/bin/bash

# Start EWW widgets for Hyprland
EWW_CONFIG_DIR="$HOME/.config/eww"

# Kill existing EWW processes
killall eww 2>/dev/null || true

# Wait a moment
sleep 1

# Start EWW daemon
eww daemon &
sleep 2

# Open widgets
eww open sysinfo-window
eww open weather-window
eww open ascii-window
eww open file-button-window
eww open youtube-window
eww open radar-window
eww open power_widget
eww open clock-window
eww open workspace-window

echo "🌿 Decay Green EWW widgets started!"
EOF

chmod +x "$SCRIPTS_DIR/start_widgets.sh"

# Create stop script
cat > "$SCRIPTS_DIR/stop_widgets.sh" << 'EOF'
#!/bin/bash

# Stop all EWW widgets
eww close-all
killall eww 2>/dev/null || true
echo "🛑 EWW widgets stopped!"
EOF

chmod +x "$SCRIPTS_DIR/stop_widgets.sh"

# Create Hyprland autostart entry
echo -e "${YELLOW}🚀 Setting up autostart...${NC}"
HYPR_CONFIG_DIR="$HOME/.config/hypr"
if [ -d "$HYPR_CONFIG_DIR" ]; then
    # Add to hyprland.conf if not already there
    if ! grep -q "start_widgets.sh" "$HYPR_CONFIG_DIR/hyprland.conf" 2>/dev/null; then
        echo "" >> "$HYPR_CONFIG_DIR/hyprland.conf"
        echo "# EWW Widgets - Decay Green Theme" >> "$HYPR_CONFIG_DIR/hyprland.conf"
        echo "exec-once = $SCRIPTS_DIR/start_widgets.sh" >> "$HYPR_CONFIG_DIR/hyprland.conf"
        echo -e "${GREEN}✓ Added autostart to hyprland.conf${NC}"
    else
        echo -e "${YELLOW}! Autostart already configured${NC}"
    fi
fi

# Final instructions
echo -e "\n${GREEN}🎉 Decay Green Theme Setup Complete!${NC}"
echo -e "${BLUE}=============================================${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo -e "1. Copy the provided eww.scss content to: ${GREEN}$EWW_CONFIG_DIR/eww.scss${NC}"
echo -e "2. Copy the provided eww.yuck content to: ${GREEN}$EWW_CONFIG_DIR/eww.yuck${NC}"
echo -e "3. Run: ${GREEN}$SCRIPTS_DIR/start_widgets.sh${NC}"
echo -e "4. Restart Hyprland or run: ${GREEN}hyprctl reload${NC}"
echo ""
echo -e "${BLUE}Useful commands:${NC}"
echo -e "Start widgets: ${GREEN}$SCRIPTS_DIR/start_widgets.sh${NC}"
echo -e "Stop widgets:  ${GREEN}$SCRIPTS_DIR/stop_widgets.sh${NC}"
echo -e "Reload EWW:    ${GREEN}eww reload${NC}"
echo ""
echo -e "${YELLOW}Customize:${NC}"
echo -e "- Edit colors in eww.scss CSS variables section"
echo -e "- Modify widget positions in eww.yuck"
echo -e "- Add your own ASCII art to random_ascii.sh"
echo -e "- Replace radar.png with actual weather radar image"
echo ""
echo -e "${GREEN}Enjoy your new Decay Green desktop! 🌿${NC}"
EOF
