# Quick Installation Guide

## One-Line Installation (Bulletproof Edition)

### If you have the repository cloned:

```bash
cd eww && chmod +x install.sh && ./install.sh
```

### Direct installation from GitHub (coming soon):

```bash
curl -sSL https://raw.githubusercontent.com/yourusername/eww/main/install.sh | bash
```

Or using wget:

```bash
wget -qO- https://raw.githubusercontent.com/yourusername/eww/main/install.sh | bash
```

## What Makes This Bulletproof?

This enhanced installation script includes:

- **Pre-flight System Checks**: Validates your environment before installation
- **Automatic Rollback**: Reverts changes if installation fails
- **Network Retry Logic**: Automatically retries failed downloads (up to 5 attempts with exponential backoff)
- **Comprehensive Error Handling**: Gracefully handles edge cases and provides helpful error messages
- **Installation Logging**: Detailed logs for troubleshooting (`/tmp/eww-install-*.log`)
- **Safe Backups**: Automatically backs up existing configurations with rollback capability
- **Dependency Verification**: Ensures all critical packages are installed correctly
- **Multiple Shell Support**: Automatically configures PATH for bash, zsh, and fish
- **Enhanced Arch Linux Support**: Detects and uses AUR helpers (yay/paru) when available

## What the installer does:

1. **Detects your Linux distribution** (Arch, Ubuntu, Debian, Fedora, etc.)
2. **Installs all dependencies:**
   - EWW (Elkowar's Wacky Widgets)
   - ImageMagick (for color extraction)
   - inotify-tools (for wallpaper watching)
   - CAVA (for music visualization)
   - Other utilities (jq, bc, socat, etc.)
3. **Compiles EWW from source** if not available in your repos
4. **Configures CAVA** for optimal music visualization (60 FPS, 32 bars)
5. **Installs widget files** to `~/.config/eww/`
6. **Sets up scripts** and makes them executable
7. **Extracts colors** from your current wallpaper
8. **Configures Hyprland** auto-start (optional)
9. **Starts the widgets** (optional)

## Supported Distributions:

- ✅ Arch Linux, Manjaro, EndeavourOS
- ✅ Ubuntu, Debian, Pop!_OS, Linux Mint
- ✅ Fedora, RHEL, CentOS
- ⚠️ Other distributions (manual dependency installation required)

## Requirements:

- **Window Manager:** Hyprland (recommended) or any wlroots-based compositor
- **Wallpaper Manager:** swww or hyprpaper (for color extraction)
- **Audio Server:** PipeWire or PulseAudio (for music visualizer)
- **Display Server:** Wayland (X11 experimental)

## Post-Installation:

After installation, the widgets will:
- Automatically match your wallpaper colors
- Update colors when you change wallpaper
- Start automatically on Hyprland launch (if configured)

## Manual Installation:

If you prefer to install manually, see the full [README.md](README.md) for detailed instructions.

## Troubleshooting:

If the installer fails:
1. Check the error messages for missing dependencies
2. Ensure you have sudo privileges
3. Try running individual steps manually (see README.md)
4. For EWW compilation issues, ensure you have Rust and Cargo installed

## Uninstallation:

To remove the widgets:

```bash
# Stop all widgets
eww kill

# Remove configuration
rm -rf ~/.config/eww

# Remove CAVA config (if you want)
rm -rf ~/.config/cava

# Remove Hyprland startup entries
# Edit ~/.config/hypr/hyprland.conf and remove EWW lines
```

## Updating:

To update to the latest version:

```bash
cd /path/to/eww
git pull
./install.sh
```

The installer will backup your existing configuration before updating.

---

**Need help?** Check the [README.md](README.md) for detailed documentation and troubleshooting tips.
