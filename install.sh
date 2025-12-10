#!/bin/bash

# --- VARIABLES ---
REPO_URL="https://github.com/saatvik333/hyprland-dotfiles.git"
CLONE_DIR="$HOME/Downloads/hyprland-oxidized-temp"
BACKUP_DIR="$HOME/.config/hypr-backup-$(date +%Y%m%d-%H%M%S)"
# The "Oxidized" look relies on these specifically:
DEPENDENCIES=("hyprland" "waybar" "rofi" "dunst" "kitty" "thunar" "ttf-jetbrains-mono-nerd" "otf-font-awesome" "git" "base-devel")
AUR_DEPENDENCIES=("swww" "wallust-git") # wallust is crucial for the color generation

# --- COLORS ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}:: Starting 'Oxidized' Hyprland Installer...${NC}"

# --- 1. CHECK FOR AUR HELPER ---
if command -v yay &> /dev/null; then
    HELPER="yay"
elif command -v paru &> /dev/null; then
    HELPER="paru"
else
    echo -e "${RED}!! No AUR helper found (yay/paru). Please install one first.${NC}"
    exit 1
fi
echo -e "${GREEN}:: Using $HELPER for AUR packages.${NC}"

# --- 2. INSTALL DEPENDENCIES ---
echo -e "${BLUE}:: Installing Official Packages...${NC}"
sudo pacman -S --needed "${DEPENDENCIES[@]}"

echo -e "${BLUE}:: Installing AUR Packages (Rust tools)...${NC}"
$HELPER -S --needed "${AUR_DEPENDENCIES[@]}"

# --- 3. BACKUP EXISTING CONFIGS ---
echo -e "${BLUE}:: Backing up existing configurations to $BACKUP_DIR...${NC}"
mkdir -p "$BACKUP_DIR"
for folder in hypr waybar kitty rofi dunst wallust; do
    if [ -d "$HOME/.config/$folder" ]; then
        mv "$HOME/.config/$folder" "$BACKUP_DIR/"
        echo -e "   -> Backed up $folder"
    fi
done

# --- 4. CLONE & INSTALL DOTFILES ---
echo -e "${BLUE}:: Cloning Repository...${NC}"
if [ -d "$CLONE_DIR" ]; then
    rm -rf "$CLONE_DIR"
fi
git clone "$REPO_URL" "$CLONE_DIR"

echo -e "${BLUE}:: Copying Config Files...${NC}"

# Note: We attempt to copy standard folders. 
# We explicitly look for these folders in the cloned repo.
cd "$CLONE_DIR" || exit

# Sometimes repos have a 'dotfiles' subdirectory or just folders at root.
# This loop checks the root of the repo for config folders.
for folder in hypr waybar kitty rofi dunst wallust; do
    if [ -d "$folder" ]; then
        cp -r "$folder" "$HOME/.config/"
        echo -e "${GREEN}   -> Installed $folder${NC}"
    elif [ -d "dotfiles/$folder" ]; then # Common alternative structure
        cp -r "dotfiles/$folder" "$HOME/.config/"
        echo -e "${GREEN}   -> Installed $folder (from dotfiles/ subdir)${NC}"
    else
        echo -e "${RED}   !! Could not find config for $folder in repo. You may need to copy it manually.${NC}"
    fi
done

# Copy scripts if they exist separately
if [ -d "scripts" ]; then
    mkdir -p "$HOME/.scripts"
    cp -r scripts/* "$HOME/.scripts/"
    chmod +x "$HOME/.scripts/"*
    echo -e "${GREEN}   -> Installed scripts to ~/.scripts${NC}"
fi

# --- 5. CLEANUP & FINAL NOTES ---
rm -rf "$CLONE_DIR"

echo -e "${BLUE}---------------------------------------------------------${NC}"
echo -e "${GREEN}:: INSTALLATION COMPLETE!${NC}"
echo -e "${BLUE}---------------------------------------------------------${NC}"
echo -e "1. **REBOOT** your system to ensure environment variables load."
echo -e "2. If icons are missing, verify 'ttf-jetbrains-mono-nerd' is selected in configs."
echo -e "3. To generate colors, set a wallpaper using 'swww' or the 'wallust' command."
echo -e "   Example: wallust run path/to/image.jpg"
echo -e "${BLUE}---------------------------------------------------------${NC}"
