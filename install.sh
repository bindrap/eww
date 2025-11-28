#!/bin/bash

# EWW Dynamic Widgets Installation Script
# One-line install: curl -sSL https://raw.githubusercontent.com/yourusername/eww/main/install.sh | bash
# Or: wget -qO- https://raw.githubusercontent.com/yourusername/eww/main/install.sh | bash

# Bulletproof error handling - don't use set -e, handle errors explicitly
set -o pipefail  # Fail on pipe errors
set -u           # Fail on undefined variables

# Installation state tracking
INSTALL_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/eww"
mkdir -p "$INSTALL_CACHE_DIR" || {
    echo "[ERROR] Failed to create install cache directory at $INSTALL_CACHE_DIR" >&2
    exit 1
}

INSTALL_LOG="$INSTALL_CACHE_DIR/install-$(date +%s).log"
ROLLBACK_ACTIONS=()
INSTALL_STATE="STARTED"

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

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$INSTALL_LOG"
}

# Pacman helpers (Arch family)
wait_for_pacman() {
    local lock_file="/var/lib/pacman/db.lck"
    local waited=0
    local max_wait=60

    if [ -f "$lock_file" ]; then
        print_info "Waiting for pacman lock to clear..."
    fi

    while [ -f "$lock_file" ]; do
        sleep 1
        ((waited++))
        if (( waited >= max_wait )); then
            print_error "pacman database lock present for over ${max_wait}s"
            print_info "If no package operation is running, remove $lock_file manually and rerun."
            return 1
        fi
    done

    return 0
}

pacman_safe() {
    wait_for_pacman || return 1
    sudo pacman "$@"
}

# Add rollback action
add_rollback() {
    ROLLBACK_ACTIONS+=("$1")
    log "Added rollback action: $1"
}

# Execute rollback
do_rollback() {
    if [ ${#ROLLBACK_ACTIONS[@]} -eq 0 ]; then
        return 0
    fi

    print_warning "Rolling back changes..."
    for ((i=${#ROLLBACK_ACTIONS[@]}-1; i>=0; i--)); do
        print_info "Rollback: ${ROLLBACK_ACTIONS[$i]}"
        eval "${ROLLBACK_ACTIONS[$i]}" || true
    done
}

# Cleanup on exit
cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ] && [ "$INSTALL_STATE" != "COMPLETE" ]; then
        print_error "Installation failed! Check log: $INSTALL_LOG"
        do_rollback
    fi
}

trap cleanup EXIT

# Check for required commands
require_command() {
    if ! command -v "$1" &>/dev/null; then
        print_error "Required command not found: $1"
        return 1
    fi
    return 0
}

# Retry function for network operations
retry_command() {
    local max_attempts=5
    local timeout=2
    local attempt=1
    local exitCode=0

    while (( attempt <= max_attempts )); do
        if "$@"; then
            return 0
        else
            exitCode=$?
        fi

        if (( attempt < max_attempts )); then
            print_warning "Command failed (attempt $attempt/$max_attempts). Retrying in ${timeout}s..."
            sleep $timeout
            timeout=$((timeout * 2))
        fi

        ((attempt++))
    done

    print_error "Command failed after $max_attempts attempts: $*"
    return $exitCode
}

# Check network connectivity
check_network() {
    print_info "Checking network connectivity..."

    local test_urls=("https://www.archlinux.org" "https://github.com" "https://www.google.com")

    for url in "${test_urls[@]}"; do
        if curl --silent --head --fail --max-time 5 "$url" &>/dev/null; then
            print_success "Network connectivity OK"
            return 0
        fi
    done

    print_error "No network connectivity detected"
    return 1
}

# Check available disk space (in MB)
check_disk_space() {
    local required_mb=1000
    local available_mb=$(df -m "$HOME" | awk 'NR==2 {print $4}')

    if [ "$available_mb" -lt "$required_mb" ]; then
        print_error "Insufficient disk space. Required: ${required_mb}MB, Available: ${available_mb}MB"
        return 1
    fi

    print_success "Disk space OK (${available_mb}MB available)"
    return 0
}

# Verify package installation
verify_package() {
    local package=$1
    if command -v "$package" &>/dev/null; then
        print_success "✓ $package installed"
        return 0
    else
        print_warning "✗ $package not found"
        return 1
    fi
}

# Safe backup function
safe_backup() {
    local target=$1
    if [ -e "$target" ]; then
        local backup="${target}.backup.$(date +%Y%m%d_%H%M%S)"
        cp -r "$target" "$backup" || return 1
        add_rollback "[ -e '$backup' ] && rm -rf '$target' && mv '$backup' '$target'"
        print_info "Backed up: $target → $backup"
        return 0
    fi
    return 0
}

# Pre-flight system checks
preflight_checks() {
    print_header "Pre-flight System Checks"

    local checks_passed=0
    local checks_total=0

    # Check if running on Linux
    ((checks_total++))
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        print_success "✓ Running on Linux"
        ((checks_passed++))
    else
        print_error "✗ This script only supports Linux"
        return 1
    fi

    # Check for bash version
    ((checks_total++))
    if [ "${BASH_VERSINFO[0]}" -ge 4 ]; then
        print_success "✓ Bash version OK (${BASH_VERSION})"
        ((checks_passed++))
    else
        print_error "✗ Bash 4.0 or higher required (found ${BASH_VERSION})"
        return 1
    fi

    # Check for curl or wget
    ((checks_total++))
    if command -v curl &>/dev/null || command -v wget &>/dev/null; then
        print_success "✓ Download tool available"
        ((checks_passed++))
    else
        print_error "✗ Neither curl nor wget found"
        return 1
    fi

    # Check for sudo
    ((checks_total++))
    if command -v sudo &>/dev/null; then
        print_success "✓ sudo available"
        ((checks_passed++))
    else
        print_error "✗ sudo not found"
        return 1
    fi

    # Check network
    ((checks_total++))
    if check_network; then
        ((checks_passed++))
    else
        print_error "✗ Network check failed"
        return 1
    fi

    # Check disk space
    ((checks_total++))
    if check_disk_space; then
        ((checks_passed++))
    else
        return 1
    fi

    # Check for Wayland (preferred for Hyprland)
    if [ -n "${WAYLAND_DISPLAY:-}" ]; then
        print_success "✓ Running on Wayland"
    else
        print_warning "⚠ Not running on Wayland (Hyprland requires Wayland)"
        print_info "This script will still install, but widgets may not work correctly"
    fi

    # Check for Hyprland
    if pgrep -x Hyprland &>/dev/null; then
        print_success "✓ Hyprland is running"
    elif command -v Hyprland &>/dev/null; then
        print_info "ℹ Hyprland installed but not currently running"
    else
        print_warning "⚠ Hyprland not detected"
    fi

    print_success "Pre-flight checks passed: $checks_passed/$checks_total"
    return 0
}

# Detect distribution
detect_distro() {
    print_info "Detecting Linux distribution..."

    if [ -f /etc/os-release ]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        DISTRO="${ID:-unknown}"
        DISTRO_VERSION="${VERSION_ID:-unknown}"
        DISTRO_PRETTY="${PRETTY_NAME:-$DISTRO}"
    elif [ -f /etc/arch-release ]; then
        DISTRO="arch"
        DISTRO_VERSION="rolling"
        DISTRO_PRETTY="Arch Linux"
    elif [ -f /etc/debian_version ]; then
        DISTRO="debian"
        DISTRO_VERSION=$(cat /etc/debian_version)
        DISTRO_PRETTY="Debian $DISTRO_VERSION"
    else
        DISTRO="unknown"
        DISTRO_VERSION="unknown"
        DISTRO_PRETTY="Unknown Linux"
    fi

    print_success "Detected: $DISTRO_PRETTY"
    log "Distribution: $DISTRO $DISTRO_VERSION"
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
        arch|manjaro|endeavouros|artix|garuda)
            print_info "Updating package database..."
            if ! retry_command pacman_safe -Sy; then
                print_error "Failed to sync package database"
                return 1
            fi

            print_info "Installing packages via pacman..."

            local packages=(
                imagemagick
                inotify-tools
                cava
                socat
                bc
                jq
                curl
                wget
                git
                rust
                cargo
                gtk3
                gtk-layer-shell
                pango
                gdk-pixbuf2
                libdbusmenu-gtk3
                pkgconf
                base-devel
            )

            local failed_packages=()

            # Try to install packages with retry logic
            if ! retry_command pacman_safe -S --needed --noconfirm "${packages[@]}"; then
                print_warning "Batch installation failed, trying individual packages..."

                for pkg in "${packages[@]}"; do
                    if ! pacman_safe -S --needed --noconfirm "$pkg" 2>/dev/null; then
                        failed_packages+=("$pkg")
                        print_warning "Failed to install: $pkg"
                    fi
                done
            fi

            # Verify critical packages
            local critical_packages=(imagemagick git rust cargo)
            for pkg in "${critical_packages[@]}"; do
                if ! pacman -Q "$pkg" &>/dev/null && ! command -v "$pkg" &>/dev/null; then
                    print_error "Critical package missing: $pkg"
                    return 1
                fi
            done

            # Try to install eww from AUR if available
            local eww_installed=false

            if command -v yay &>/dev/null; then
                print_info "Installing eww from AUR using yay..."
                if retry_command yay -S --needed --noconfirm eww-git; then
                    eww_installed=true
                else
                    print_warning "Could not install eww from AUR with yay"
                fi
            elif command -v paru &>/dev/null; then
                print_info "Installing eww from AUR using paru..."
                if retry_command paru -S --needed --noconfirm eww-git; then
                    eww_installed=true
                else
                    print_warning "Could not install eww from AUR with paru"
                fi
            else
                print_warning "No AUR helper found (yay/paru)"
                print_info "Install an AUR helper for easier eww installation:"
                print_info "  sudo pacman -S --needed git base-devel && git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si"
            fi

            if ! $eww_installed; then
                print_info "Will compile eww from source instead"
            fi
            ;;

        ubuntu|debian|pop|linuxmint|neon)
            print_info "Updating package database..."
            if ! retry_command sudo apt update; then
                print_error "Failed to update package database"
                return 1
            fi

            print_info "Installing packages via apt..."
            retry_command sudo apt install -y \
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
                rustc || {
                    print_warning "Some packages may have failed to install"
                    # Verify critical ones
                    for pkg in imagemagick git cargo; do
                        if ! dpkg -l | grep -q "^ii  $pkg"; then
                            print_error "Critical package missing: $pkg"
                            return 1
                        fi
                    done
                }
            ;;

        fedora|rhel|centos|rocky|alma)
            print_info "Installing packages via dnf..."
            retry_command sudo dnf install -y \
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
                rust || {
                    print_warning "Some packages may have failed to install"
                }
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
    if command -v eww &>/dev/null; then
        print_success "EWW is already installed"
        eww --version || print_warning "eww found but version check failed"
        return 0
    fi

    print_header "Compiling EWW from Source"
    print_info "EWW not found in PATH. Compiling from source..."

    # Verify rust/cargo are available
    if ! command -v cargo &>/dev/null; then
        print_error "cargo not found. Cannot compile eww from source."
        return 1
    fi

    print_info "Rust version: $(rustc --version 2>/dev/null || echo 'unknown')"
    print_info "Cargo version: $(cargo --version 2>/dev/null || echo 'unknown')"

    # Create temp directory
    local TMP_DIR
    local TMP_BASE="${XDG_CACHE_HOME:-$HOME/.cache}/eww-build"

    # Use user cache directory instead of /tmp to avoid quota issues
    if ! mkdir -p "$TMP_BASE"; then
        print_error "Failed to create build cache directory at $TMP_BASE"
        return 1
    fi

    TMP_DIR=$(mktemp -d -p "$TMP_BASE" eww-XXXX) || {
        print_error "Failed to create temp directory in $TMP_BASE"
        return 1
    }

    # Keep builds out of /tmp to avoid quota issues and reuse cache space
    export CARGO_TARGET_DIR="$TMP_DIR/target"
    export TMPDIR="$TMP_DIR/tmp"
    mkdir -p "$CARGO_TARGET_DIR" "$TMPDIR" || {
        print_error "Failed to prepare build directories under $TMP_DIR"
        return 1
    }

    add_rollback "rm -rf '$TMP_DIR'"

    print_info "Working in: $TMP_DIR"
    cd "$TMP_DIR" || return 1

    print_info "Cloning EWW repository..."
    if ! retry_command git clone --depth 1 https://github.com/elkowar/eww.git; then
        print_error "Failed to clone EWW repository"
        cd "$HOME" || true
        rm -rf "$TMP_DIR"
        return 1
    fi

    cd eww || {
        print_error "Failed to enter eww directory"
        cd "$HOME" || true
        rm -rf "$TMP_DIR"
        return 1
    }

    print_info "Building EWW (this may take 5-15 minutes depending on your system)..."
    print_info "You can monitor progress in: $INSTALL_LOG"

    # Determine features based on environment
    local features="wayland"
    if [ -z "${WAYLAND_DISPLAY:-}" ]; then
        features="x11"
        print_info "Building with X11 support (no Wayland session detected)"
    else
        print_info "Building with Wayland support"
    fi

    # Build with error handling
    if ! cargo build --release --no-default-features --features "$features" 2>&1 | tee -a "$INSTALL_LOG"; then
        print_error "EWW compilation failed!"
        print_info "Check the log file for details: $INSTALL_LOG"
        print_info "Common issues:"
        print_info "  - Missing development libraries (gtk3, gtk-layer-shell, etc.)"
        print_info "  - Insufficient RAM (try closing other applications)"
        print_info "  - Disk space (ensure you have at least 2GB free)"
        cd "$HOME" || true
        rm -rf "$TMP_DIR"
        return 1
    fi

    # Verify binary was created
    if [ ! -f "target/release/eww" ]; then
        print_error "EWW binary not found after compilation"
        cd "$HOME" || true
        rm -rf "$TMP_DIR"
        return 1
    fi

    print_info "Installing EWW to ~/.local/bin/..."
    mkdir -p "$HOME/.local/bin" || {
        print_error "Failed to create ~/.local/bin"
        cd "$HOME" || true
        rm -rf "$TMP_DIR"
        return 1
    }

    cp target/release/eww "$HOME/.local/bin/" || {
        print_error "Failed to copy eww binary"
        cd "$HOME" || true
        rm -rf "$TMP_DIR"
        return 1
    }

    chmod +x "$HOME/.local/bin/eww"

    # Add to PATH if not already there
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        print_info "Adding ~/.local/bin to PATH..."

        # Detect shell and update config
        if [ -n "${BASH_VERSION:-}" ] && [ -f "$HOME/.bashrc" ]; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
            print_info "Updated ~/.bashrc"
        fi

        if [ -f "$HOME/.zshrc" ]; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
            print_info "Updated ~/.zshrc"
        fi

        if [ -f "$HOME/.config/fish/config.fish" ]; then
            echo 'set -gx PATH $HOME/.local/bin $PATH' >> "$HOME/.config/fish/config.fish"
            print_info "Updated ~/.config/fish/config.fish"
        fi

        export PATH="$HOME/.local/bin:$PATH"
    fi

    # Cleanup
    cd "$HOME" || true
    rm -rf "$TMP_DIR"

    # Verify installation
    if command -v eww &>/dev/null; then
        print_success "EWW compiled and installed successfully"
        eww --version || true
        log "EWW installed to: $(which eww)"
        return 0
    else
        print_error "EWW installation failed - command not found after install"
        print_info "Try running: export PATH=\"\$HOME/.local/bin:\$PATH\""
        return 1
    fi
}

# Create CAVA configuration
create_cava_config() {
    print_header "Configuring CAVA"

    # Verify cava is installed
    if ! command -v cava &>/dev/null; then
        print_warning "CAVA not found, skipping configuration"
        return 0
    fi

    mkdir -p "$CAVA_CONFIG_DIR" || {
        print_error "Failed to create CAVA config directory"
        return 1
    }

    if [ -f "$CAVA_CONFIG_DIR/config" ]; then
        if ! safe_backup "$CAVA_CONFIG_DIR/config"; then
            print_error "Failed to backup existing CAVA config"
            return 1
        fi
    fi

    print_info "Creating CAVA configuration for EWW..."
    if ! cat > "$CAVA_CONFIG_DIR/config" << 'EOF'
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
    then
        print_error "Failed to create CAVA configuration"
        return 1
    fi

    print_success "CAVA configuration created at $CAVA_CONFIG_DIR/config"
    return 0
}

# Install widget files
install_widgets() {
    print_header "Installing EWW Widgets"

    # Backup existing config if it exists
    if [ -d "$EWW_CONFIG_DIR" ]; then
        if ! safe_backup "$EWW_CONFIG_DIR"; then
            print_error "Failed to backup existing EWW config"
            return 1
        fi
    fi

    # Create config directory
    mkdir -p "$EWW_CONFIG_DIR" || {
        print_error "Failed to create EWW config directory"
        return 1
    }

    # Determine source directory (either current dir or use current git repo)
    local SOURCE_DIR
    local CLEANUP_SOURCE=false

    # Check if we're in the eww repo directory
    if [ -f "eww.yuck" ] && [ -f "eww.scss" ]; then
        SOURCE_DIR="$(pwd)"
        print_info "Using current directory as source: $SOURCE_DIR"
    else
        print_warning "Widget files not found in current directory"
        print_info "Attempting to locate widget files..."

        # Try to find the repo in common locations
        local possible_dirs=(
            "$HOME/eww"
            "$HOME/Documents/eww"
            "$HOME/Downloads/eww"
            "$(dirname "$(readlink -f "$0")")"
        )

        for dir in "${possible_dirs[@]}"; do
            if [ -f "$dir/eww.yuck" ]; then
                SOURCE_DIR="$dir"
                print_success "Found widget files at: $SOURCE_DIR"
                break
            fi
        done

        if [ -z "$SOURCE_DIR" ]; then
            print_error "Widget files not found!"
            print_info "Please ensure you have cloned the repository and run this script from within it."
            print_info "Or specify the path: SOURCE_DIR=/path/to/eww ./install.sh"
            return 1
        fi
    fi

    # Verify required files exist
    local required_files=("eww.yuck" "eww.scss")
    for file in "${required_files[@]}"; do
        if [ ! -f "$SOURCE_DIR/$file" ]; then
            print_error "Required file not found: $file"
            return 1
        fi
    done

    print_info "Copying widget files from: $SOURCE_DIR"

    # Copy main config files
    cp -v "$SOURCE_DIR/eww.yuck" "$EWW_CONFIG_DIR/" || {
        print_error "Failed to copy eww.yuck"
        return 1
    }

    cp -v "$SOURCE_DIR/eww.scss" "$EWW_CONFIG_DIR/" || {
        print_error "Failed to copy eww.scss"
        return 1
    }

    # Copy optional files
    [ -f "$SOURCE_DIR/ascii.yuck" ] && cp -v "$SOURCE_DIR/ascii.yuck" "$EWW_CONFIG_DIR/" || true
    [ -f "$SOURCE_DIR/system.yuck" ] && cp -v "$SOURCE_DIR/system.yuck" "$EWW_CONFIG_DIR/" || true

    # Copy scripts directory
    if [ -d "$SOURCE_DIR/scripts" ]; then
        print_info "Copying scripts..."
        mkdir -p "$EWW_CONFIG_DIR/scripts"
        cp -rv "$SOURCE_DIR/scripts/"* "$EWW_CONFIG_DIR/scripts/" || {
            print_warning "Some scripts may have failed to copy"
        }

        # Make all scripts executable
        print_info "Making scripts executable..."
        find "$EWW_CONFIG_DIR/scripts" -type f -name "*.sh" -exec chmod +x {} \; || {
            print_warning "Failed to make some scripts executable"
        }
    else
        print_warning "Scripts directory not found in source"
    fi

    # Copy assets directory
    if [ -d "$SOURCE_DIR/assets" ]; then
        print_info "Copying assets..."
        mkdir -p "$EWW_CONFIG_DIR/assets"
        cp -rv "$SOURCE_DIR/assets/"* "$EWW_CONFIG_DIR/assets/" 2>/dev/null || {
            print_warning "Some assets may have failed to copy"
        }
    fi

    # Copy README if available
    [ -f "$SOURCE_DIR/README.md" ] && cp -v "$SOURCE_DIR/README.md" "$EWW_CONFIG_DIR/" || true

    # Verify installation
    if [ -f "$EWW_CONFIG_DIR/eww.yuck" ] && [ -f "$EWW_CONFIG_DIR/eww.scss" ]; then
        print_success "Widget files installed to $EWW_CONFIG_DIR"
        return 0
    else
        print_error "Widget installation verification failed"
        return 1
    fi
}

# Configure Hyprland startup (optional)
configure_hyprland() {
    print_header "Hyprland Configuration"

    # Check if Hyprland config exists
    if [ ! -f "$HYPR_CONFIG" ]; then
        # Try alternative location
        if [ -f "$HOME/.config/hypr/hyprland.conf" ]; then
            HYPR_CONFIG="$HOME/.config/hypr/hyprland.conf"
        else
            print_warning "Hyprland config not found"
            print_info "Skipping Hyprland auto-start configuration"
            print_info "You can manually add EWW to your Hyprland config later"
            return 0
        fi
    fi

    print_info "Found Hyprland config: $HYPR_CONFIG"

    # Check if already configured
    if grep -q "eww daemon" "$HYPR_CONFIG" || grep -q "eww open" "$HYPR_CONFIG"; then
        print_warning "EWW already configured in Hyprland config"
        read -p "Reconfigure anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi

    read -p "Add EWW widgets to Hyprland startup? (Y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        # Backup config
        if ! safe_backup "$HYPR_CONFIG"; then
            print_error "Failed to backup Hyprland config"
            return 1
        fi

        print_info "Adding EWW to Hyprland startup..."

        # Add startup commands
        if ! cat >> "$HYPR_CONFIG" << 'EOF'

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
        then
            print_error "Failed to add EWW to Hyprland config"
            return 1
        fi

        print_success "Added EWW to Hyprland startup"
        print_info "Changes will take effect on next Hyprland restart"
    else
        print_info "Skipping Hyprland auto-start configuration"
    fi

    return 0
}

# Initialize colors from current wallpaper
initialize_colors() {
    print_header "Initializing Wallpaper Colors"

    local color_script="$EWW_CONFIG_DIR/scripts/update_colors_from_wallpaper.sh"

    if [ ! -f "$color_script" ]; then
        print_warning "Color extraction script not found at: $color_script"
        print_info "Skipping color initialization"
        return 0
    fi

    if [ ! -x "$color_script" ]; then
        print_info "Making color script executable..."
        chmod +x "$color_script" || {
            print_warning "Failed to make color script executable"
            return 0
        }
    fi

    print_info "Extracting colors from current wallpaper..."

    # Check if imagemagick is available
    if ! command -v convert &>/dev/null && ! command -v magick &>/dev/null; then
        print_warning "ImageMagick not found, skipping color extraction"
        return 0
    fi

    # Try to extract colors
    if bash "$color_script" 2>&1 | tee -a "$INSTALL_LOG"; then
        print_success "Colors extracted successfully"
    else
        print_warning "Could not extract colors (wallpaper may not be set)"
        print_info "Colors will be extracted automatically when you set a wallpaper"
    fi

    return 0
}

# Start EWW widgets
start_widgets() {
    print_header "Starting EWW Widgets"

    # Verify eww is available
    if ! command -v eww &>/dev/null; then
        print_error "eww command not found in PATH"
        print_info "Try: export PATH=\"\$HOME/.local/bin:\$PATH\""
        return 1
    fi

    read -p "Start EWW widgets now? (Y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        # Check if daemon is already running
        if pgrep -x eww &>/dev/null; then
            print_warning "EWW daemon already running, restarting..."
            eww kill 2>/dev/null || true
            sleep 1
        fi

        print_info "Starting EWW daemon..."
        eww daemon 2>&1 | tee -a "$INSTALL_LOG" &
        local daemon_pid=$!

        sleep 2

        # Verify daemon is running
        if ! pgrep -x eww &>/dev/null; then
            print_error "EWW daemon failed to start"
            print_info "Check logs: eww logs"
            return 1
        fi

        print_success "EWW daemon started"

        # List of widgets to open
        local widgets=(
            "sysinfo-window"
            "power_widget"
            "cava-window"
            "clock-window"
            "volume-window"
            "workspace-window"
        )

        print_info "Opening widgets..."
        local failed_widgets=()

        for widget in "${widgets[@]}"; do
            if eww open "$widget" 2>/dev/null; then
                print_info "  ✓ $widget"
            else
                print_warning "  ✗ $widget (may not be defined in config)"
                failed_widgets+=("$widget")
            fi
        done

        # Start wallpaper watcher if script exists
        local watcher_script="$EWW_CONFIG_DIR/scripts/watch_wallpaper_inotify.sh"
        if [ -f "$watcher_script" ] && [ -x "$watcher_script" ]; then
            print_info "Starting wallpaper watcher..."
            nohup "$watcher_script" &>/dev/null &
            print_success "Wallpaper watcher started"
        else
            print_warning "Wallpaper watcher script not found or not executable"
        fi

        if [ ${#failed_widgets[@]} -eq 0 ]; then
            print_success "All widgets started successfully!"
        else
            print_warning "Some widgets failed to start: ${failed_widgets[*]}"
            print_info "This is normal if those widgets are not configured yet"
        fi
    else
        print_info "Skipping widget startup"
        print_info "You can start widgets later with: eww open <widget-name>"
    fi

    return 0
}

# Main installation process
main() {
    print_header "EWW Dynamic Widgets Installer - Bulletproof Edition"

    print_info "Installation log: $INSTALL_LOG"
    log "Installation started at $(date)"

    # Run checks
    check_root || exit 1
    preflight_checks || exit 1
    detect_distro || exit 1

    # Install dependencies
    if ! install_dependencies; then
        print_error "Dependency installation failed"
        exit 1
    fi

    # Install or verify eww
    if ! install_eww_from_source; then
        print_error "EWW installation failed"
        print_info "You may need to install additional development libraries"
        exit 1
    fi

    # Configure CAVA
    if ! create_cava_config; then
        print_warning "CAVA configuration failed, but continuing..."
    fi

    # Install widget files
    if ! install_widgets; then
        print_error "Widget installation failed"
        exit 1
    fi

    # Initialize colors (non-critical)
    initialize_colors || print_warning "Color initialization failed, but continuing..."

    # Configure Hyprland (non-critical)
    configure_hyprland || print_warning "Hyprland configuration failed, but continuing..."

    # Start widgets (non-critical)
    start_widgets || print_warning "Widget startup failed, but installation is complete"

    # Mark installation as complete
    INSTALL_STATE="COMPLETE"

    print_header "Installation Complete!"

    echo -e "${GREEN}✓${NC} EWW Dynamic Widgets installed successfully!"
    echo -e "\n${BLUE}Installation Summary:${NC}"
    echo "  • Configuration directory: $EWW_CONFIG_DIR"
    echo "  • EWW binary: $(which eww 2>/dev/null || echo 'Not in PATH - add ~/.local/bin to PATH')"
    echo "  • Installation log: $INSTALL_LOG"

    echo -e "\n${BLUE}Next steps:${NC}"
    echo "  1. Set a wallpaper using swww or hyprpaper"
    echo "  2. Colors will automatically update to match your wallpaper"
    echo "  3. Widgets will start automatically on next Hyprland launch (if configured)"

    echo -e "\n${BLUE}Manual controls:${NC}"
    echo "  • Start daemon: eww daemon"
    echo "  • Open widget: eww open <widget-name>"
    echo "  • Close widget: eww close <widget-name>"
    echo "  • Kill all: eww kill"
    echo "  • Update colors: ~/.config/eww/scripts/update_colors_from_wallpaper.sh"
    echo "  • View logs: eww logs"

    echo -e "\n${BLUE}Available widgets:${NC}"
    echo "  • sysinfo-window (system information)"
    echo "  • power_widget (power menu)"
    echo "  • cava-window (music visualizer)"
    echo "  • clock-window (clock)"
    echo "  • volume-window (volume control)"
    echo "  • workspace-window (workspace indicator)"
    echo "  • weather-window (weather)"
    echo "  • music-window (music player)"

    echo -e "\n${BLUE}Troubleshooting:${NC}"
    echo "  • If eww not found: source ~/.bashrc or logout/login"
    echo "  • Config location: $EWW_CONFIG_DIR"
    echo "  • Documentation: $EWW_CONFIG_DIR/README.md"
    echo "  • Installation log: $INSTALL_LOG"

    echo -e "\n${GREEN}Enjoy your new widgets!${NC}\n"

    log "Installation completed successfully at $(date)"
}

# Run main installation
main "$@"
