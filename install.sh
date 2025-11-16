#!/bin/bash

# EWW Dynamic Widgets Installation Script
# One-line install: curl -sSL https://raw.githubusercontent.com/yourusername/eww/main/install.sh | bash
# Or: wget -qO- https://raw.githubusercontent.com/yourusername/eww/main/install.sh | bash

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
EWW_CONFIG_DIR="$HOME/.config/eww"
CAVA_CONFIG_DIR="$HOME/.config/cava"
HYPR_CONFIG="$HOME/.config/hypr/hyprland.conf"

# Print functions
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "\n${BLUE}=====================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}=====================================${NC}\n"
}

# Detect distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    elif [ -f /etc/arch-release ]; then
        DISTRO="arch"
    elif [ -f /etc/debian_version ]; then
        DISTRO="debian"
    else
        DISTRO="unknown"
    fi
    print_info "Detected distribution: $DISTRO"
}

# Check if running as root
check_root() {
    if [ "$EUID" -eq 0 ]; then
        print_warning "Please do not run this script as root or with sudo"
        print_info "The script will ask for sudo password when needed"
        exit 1
    fi
}

# Install dependencies based on distro
install_dependencies() {
    print_header "Installing Dependencies"

    case $DISTRO in
        arch|manjaro|endeavouros)
            print_info "Installing packages via pacman..."
            sudo pacman -S --needed --noconfirm \
                imagemagick \
                inotify-tools \
                cava \
                socat \
                bc \
                jq \
                curl \
                wget \
                git \
                rust \
                cargo \
                gtk3 \
                gtk-layer-shell \
                pango \
                gdk-pixbuf2 \
                libdbusmenu-gtk3 || print_warning "Some packages may have failed to install"

            # Try to install eww from AUR if available
            if command -v yay &> /dev/null; then
                print_info "Installing eww from AUR using yay..."
                yay -S --needed --noconfirm eww || print_warning "Could not install eww from AUR"
            elif command -v paru &> /dev/null; then
                print_info "Installing eww from AUR using paru..."
                paru -S --needed --noconfirm eww || print_warning "Could not install eww from AUR"
            else
                print_warning "No AUR helper found. Will compile eww from source."
            fi
            ;;

        ubuntu|debian|pop|linuxmint)
            print_info "Installing packages via apt..."
            sudo apt update
            sudo apt install -y \
                imagemagick \
                inotify-tools \
                cava \
                socat \
                bc \
                jq \
                curl \
                wget \
                git \
                build-essential \
                libgtk-3-dev \
                libgtk-layer-shell-dev \
                libpango1.0-dev \
                libgdk-pixbuf2.0-dev \
                libdbusmenu-gtk3-dev \
                cargo \
                rustc || print_warning "Some packages may have failed to install"
            ;;

        fedora|rhel|centos)
            print_info "Installing packages via dnf..."
            sudo dnf install -y \
                ImageMagick \
                inotify-tools \
                cava \
                socat \
                bc \
                jq \
                curl \
                wget \
                git \
                gtk3-devel \
                gtk-layer-shell-devel \
                pango-devel \
                gdk-pixbuf2-devel \
                libdbusmenu-gtk3-devel \
                cargo \
                rust || print_warning "Some packages may have failed to install"
            ;;

        *)
            print_error "Unsupported distribution: $DISTRO"
            print_info "Please install the following packages manually:"
            echo "  - eww (Elkowar's Wacky Widgets)"
            echo "  - imagemagick"
            echo "  - inotify-tools"
            echo "  - cava"
            echo "  - socat, bc, jq, curl, wget, git"
            read -p "Continue anyway? (y/N) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
            ;;
    esac

    print_success "Dependencies installed"
}

# Compile and install eww from source if not available
install_eww_from_source() {
    if ! command -v eww &> /dev/null; then
        print_header "Compiling EWW from Source"

        print_info "EWW not found in PATH. Compiling from source..."

        # Create temp directory
        TMP_DIR=$(mktemp -d)
        cd "$TMP_DIR"

        print_info "Cloning EWW repository..."
        git clone https://github.com/elkowar/eww.git
        cd eww

        print_info "Building EWW (this may take several minutes)..."
        cargo build --release --no-default-features --features x11

        print_info "Installing EWW to ~/.local/bin/..."
        mkdir -p "$HOME/.local/bin"
        cp target/release/eww "$HOME/.local/bin/"

        # Add to PATH if not already there
        if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
            print_info "Adding ~/.local/bin to PATH..."
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc" 2>/dev/null || true
            export PATH="$HOME/.local/bin:$PATH"
        fi

        # Cleanup
        cd ~
        rm -rf "$TMP_DIR"

        if command -v eww &> /dev/null; then
            print_success "EWW compiled and installed successfully"
        else
            print_error "EWW installation failed"
            exit 1
        fi
    else
        print_success "EWW is already installed"
        eww --version
    fi
}

# Create CAVA configuration
create_cava_config() {
    print_header "Configuring CAVA"

    mkdir -p "$CAVA_CONFIG_DIR"

    if [ -f "$CAVA_CONFIG_DIR/config" ]; then
        print_warning "CAVA config already exists. Creating backup..."
        cp "$CAVA_CONFIG_DIR/config" "$CAVA_CONFIG_DIR/config.backup.$(date +%Y%m%d_%H%M%S)"
    fi

    print_info "Creating CAVA configuration for EWW..."
    cat > "$CAVA_CONFIG_DIR/config" << 'EOF'
[general]
framerate = 60
bars = 32

[input]
method = pipewire
source = auto

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 10
bar_delimiter = 59

[smoothing]
noise_reduction = 88

[eq]
1 = 1
2 = 1
3 = 1
4 = 1
5 = 1
EOF

    print_success "CAVA configuration created"
}

# Install widget files
install_widgets() {
    print_header "Installing EWW Widgets"

    # Backup existing config if it exists
    if [ -d "$EWW_CONFIG_DIR" ]; then
        print_warning "Existing EWW config found. Creating backup..."
        BACKUP_DIR="$EWW_CONFIG_DIR.backup.$(date +%Y%m%d_%H%M%S)"
        cp -r "$EWW_CONFIG_DIR" "$BACKUP_DIR"
        print_info "Backup created at: $BACKUP_DIR"
    fi

    # Create config directory
    mkdir -p "$EWW_CONFIG_DIR"

    # Determine source directory (either current dir or cloned repo)
    if [ -f "eww.yuck" ]; then
        SOURCE_DIR="$(pwd)"
    else
        print_info "Cloning widgets repository..."
        TMP_DIR=$(mktemp -d)
        cd "$TMP_DIR"
        # Replace with your actual repository URL
        git clone https://github.com/yourusername/eww-widgets.git .
        SOURCE_DIR="$TMP_DIR"
    fi

    print_info "Copying widget files..."
    cp -v "$SOURCE_DIR/eww.yuck" "$EWW_CONFIG_DIR/"
    cp -v "$SOURCE_DIR/eww.scss" "$EWW_CONFIG_DIR/"
    cp -v "$SOURCE_DIR/ascii.yuck" "$EWW_CONFIG_DIR/" 2>/dev/null || true
    cp -v "$SOURCE_DIR/system.yuck" "$EWW_CONFIG_DIR/" 2>/dev/null || true

    # Copy scripts
    print_info "Copying scripts..."
    mkdir -p "$EWW_CONFIG_DIR/scripts"
    cp -rv "$SOURCE_DIR/scripts/"* "$EWW_CONFIG_DIR/scripts/"

    # Copy assets
    print_info "Copying assets..."
    mkdir -p "$EWW_CONFIG_DIR/assets"
    cp -rv "$SOURCE_DIR/assets/"* "$EWW_CONFIG_DIR/assets/" 2>/dev/null || true

    # Make all scripts executable
    print_info "Making scripts executable..."
    chmod +x "$EWW_CONFIG_DIR/scripts/"*.sh

    # Copy README
    cp -v "$SOURCE_DIR/README.md" "$EWW_CONFIG_DIR/" 2>/dev/null || true

    print_success "Widget files installed to $EWW_CONFIG_DIR"
}

# Configure Hyprland startup (optional)
configure_hyprland() {
    print_header "Hyprland Configuration"

    if [ ! -f "$HYPR_CONFIG" ]; then
        print_warning "Hyprland config not found at $HYPR_CONFIG"
        print_info "Skipping Hyprland auto-start configuration"
        return
    fi

    read -p "Add EWW widgets to Hyprland startup? (Y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        print_info "Adding EWW to Hyprland startup..."

        # Check if already configured
        if grep -q "eww daemon" "$HYPR_CONFIG"; then
            print_warning "EWW startup already configured in Hyprland"
        else
            # Add startup commands
            cat >> "$HYPR_CONFIG" << 'EOF'

# EWW Widget Configuration
exec-once = eww daemon
exec-once = sleep 2 && eww open sysinfo-window
exec-once = eww open power_widget
exec-once = eww open cava-window
exec-once = eww open clock-window
exec-once = eww open volume-window
exec-once = eww open workspace-window
exec-once = ~/.config/eww/scripts/watch_wallpaper_inotify.sh &
EOF
            print_success "Added EWW to Hyprland startup"
        fi
    fi
}

# Initialize colors from current wallpaper
initialize_colors() {
    print_header "Initializing Wallpaper Colors"

    print_info "Extracting colors from current wallpaper..."
    if [ -f "$EWW_CONFIG_DIR/scripts/update_colors_from_wallpaper.sh" ]; then
        bash "$EWW_CONFIG_DIR/scripts/update_colors_from_wallpaper.sh" || print_warning "Could not extract colors (wallpaper may not be set)"
    else
        print_warning "Color extraction script not found"
    fi
}

# Start EWW widgets
start_widgets() {
    print_header "Starting EWW Widgets"

    read -p "Start EWW widgets now? (Y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        print_info "Starting EWW daemon..."
        eww daemon &>/dev/null || print_warning "EWW daemon may already be running"

        sleep 2

        print_info "Opening widgets..."
        eww open sysinfo-window &>/dev/null &
        eww open power_widget &>/dev/null &
        eww open cava-window &>/dev/null &
        eww open clock-window &>/dev/null &
        eww open volume-window &>/dev/null &
        eww open workspace-window &>/dev/null &

        print_info "Starting wallpaper watcher..."
        nohup "$EWW_CONFIG_DIR/scripts/watch_wallpaper_inotify.sh" &>/dev/null &

        print_success "Widgets started!"
    fi
}

# Main installation process
main() {
    print_header "EWW Dynamic Widgets Installer"

    check_root
    detect_distro
    install_dependencies
    install_eww_from_source
    create_cava_config
    install_widgets
    initialize_colors
    configure_hyprland
    start_widgets

    print_header "Installation Complete!"

    echo -e "${GREEN}✓${NC} EWW Dynamic Widgets installed successfully!"
    echo -e "\n${BLUE}Next steps:${NC}"
    echo "  1. Set a wallpaper using swww or hyprpaper"
    echo "  2. Colors will automatically update to match your wallpaper"
    echo "  3. Widgets will start automatically on next Hyprland launch"
    echo -e "\n${BLUE}Manual controls:${NC}"
    echo "  - Start widgets: eww open <window-name>"
    echo "  - Stop widgets: eww close <window-name>"
    echo "  - Update colors: ~/.config/eww/scripts/update_colors_from_wallpaper.sh"
    echo "  - View logs: eww logs"
    echo -e "\n${BLUE}Available widgets:${NC}"
    echo "  - sysinfo-window (system information)"
    echo "  - power_widget (power menu)"
    echo "  - cava-window (music visualizer)"
    echo "  - clock-window (clock)"
    echo "  - volume-window (volume control)"
    echo "  - workspace-window (workspace indicator)"
    echo "  - weather-window (weather)"
    echo "  - music-window (music player)"
    echo -e "\n${BLUE}Documentation:${NC} $EWW_CONFIG_DIR/README.md"
    echo -e "\n${GREEN}Enjoy your new widgets!${NC}\n"
}

# Run main installation
main
