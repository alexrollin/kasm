#!/bin/bash

# How This Script Works and How to Update It:
# - Purpose: This script installs or removes software on a Kasm Ubuntu system, with a GUI for installs and CLI options for removal.
# - Usage:
#   - Install: Run './install_software_gui.sh' to launch a GUI where you type a comma-separated list of software (e.g., 'fish, nano'). Windsurf is installed by default with Kasm-specific fixes (--no-sandbox and %U in .desktop).
#   - Remove: Run './install_software_gui.sh r-<software>' to remove a specific software (e.g., './install_software_gui.sh r-windsurf' removes Windsurf).
# - Structure:
#   - Removal functions (e.g., remove_windsurf) are defined first. Add new ones for each software following the same pattern.
#   - A CLI check (if [ "$1" = "r-<software>" ]) triggers the matching removal function.
#   - If no CLI arg, it runs the GUI install process.
# - Updating for New Software:
#   1. Add a 'remove_<software>()' function with uninstall steps (e.g., 'sudo apt purge -y <software>', config cleanup).
#   2. Add an 'if [ "$1" = "r-<software>" ]' check below existing ones to call the new function.
#   3. In the GUI install section, add steps to install/configure the new software (e.g., repo setup, apt install, fixes).
#   4. Update the Zenity prompt to list the new software as an option.
# - Example: To add 'nano':
#   - Add 'remove_nano() { sudo apt purge -y nano; rm -rf ~/.nano; ... }'
#   - Add 'if [ "$1" = "r-nano" ]; then remove_nano; fi'
#   - Install nano in the GUI loop if listed by user.

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to remove Windsurf
remove_windsurf() {
    echo -e "${GREEN}Starting Windsurf removal...${NC}"
    echo -e "${GREEN}Removing Windsurf package...${NC}"
    sudo apt purge -y windsurf || echo -e "${RED}Failed to purge Windsurf package.${NC}"
    echo -e "${GREEN}Removing user configuration files...${NC}"
    rm -rf ~/.codeium/windsurf ~/.config/Windsurf || echo -e "${RED}Failed to remove user configs.${NC}"
    echo -e "${GREEN}Removing Windsurf APT repository and GPG key...${NC}"
    sudo rm -f /etc/apt/sources.list.d/windsurf.list || echo -e "${RED}Failed to remove APT repo file.${NC}"
    sudo rm -f /usr/share/keyrings/windsurf-stable-archive-keyring.gpg || echo -e "${RED}Failed to remove GPG key.${NC}"
    echo -e "${GREEN}Cleaning APT cache...${NC}"
    sudo apt update -y || echo -e "${RED}APT update failed.${NC}"
    sudo apt autoremove -y || echo -e "${RED}APT autoremove failed.${NC}"
    sudo apt autoclean || echo -e "${RED}APT autoclean failed.${NC}"
    echo -e "${GREEN}Verifying Windsurf removal...${NC}"
    if dpkg -l | grep -q windsurf; then
        echo -e "${RED}Windsurf still detected.${NC}"
    else
        echo -e "${GREEN}Windsurf not found—removal complete!${NC}"
    fi
    if [ -f /usr/share/windsurf/bin/windsurf ]; then
        echo -e "${RED}Windsurf binary still exists.${NC}"
    else
        echo -e "${GREEN}Windsurf binary removed.${NC}"
    fi
    echo -e "${GREEN}Windsurf removal finished!${NC}"
    exit 0
}

# Function to remove makeself
remove_makeself() {
    echo -e "${GREEN}Starting makeself removal...${NC}"
    echo -e "${GREEN}Removing makeself package...${NC}"
    sudo apt purge -y makeself || echo -e "${RED}Failed to purge makeself package.${NC}"
    echo -e "${GREEN}Cleaning APT cache...${NC}"
    sudo apt update -y || echo -e "${RED}APT update failed.${NC}"
    sudo apt autoremove -y || echo -e "${RED}APT autoremove failed.${NC}"
    sudo apt autoclean || echo -e "${RED}APT autoclean failed.${NC}"
    echo -e "${GREEN}Verifying makeself removal...${NC}"
    if dpkg -l | grep -q makeself; then
        echo -e "${RED}makeself still detected.${NC}"
    else
        echo -e "${GREEN}makeself not found—removal complete!${NC}"
    fi
    if [ -f /usr/bin/makeself ]; then
        echo -e "${RED}makeself binary still exists.${NC}"
    else
        echo -e "${GREEN}makeself binary removed.${NC}"
    fi
    echo -e "${GREEN}makeself removal finished!${NC}"
    exit 0
}

# Check for command-line arguments
if [ "$1" = "r-windsurf" ]; then
    remove_windsurf
fi
if [ "$1" = "r-makeself" ]; then
    remove_makeself
fi

# Check if running in a graphical environment for GUI mode
if [ -z "$DISPLAY" ]; then
    echo "No graphical environment detected. Please run this in a GUI session unless using 'r-<software>'."
    exit 1
fi

# Check if Zenity is installed
if ! command -v zenity &> /dev/null; then
    zenity --info --text="Zenity not found. Installing it first..." --title="Setup" --no-cancel
    sudo apt update -y && sudo apt install -y zenity || {
        zenity --error --text="Failed to install Zenity. Exiting." --title="Error"
        exit 1
    }
fi

# Prompt user for additional software list via GUI
software_list=$(zenity --entry \
    --title="Software Installer" \
    --text="Enter a comma-separated list of software (e.g., fish, nano, makeself).\nWindsurf will be installed by default with Kasm fixes.\nUse './install_software_gui.sh r-<software>' to remove (e.g., 'r-windsurf', 'r-makeself')." \
    --width=400)

# Exit if canceled
if [ $? -ne 0 ]; then
    zenity --error --text="Installation canceled." --title="Canceled"
    exit 1
fi

# Step 1: Add Windsurf repository
zenity --info --text="Setting up Windsurf repository..." --title="Progress" --no-cancel &
repo_pid=$!
curl -fsSL "https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/windsurf.gpg" | sudo gpg --dearmor -o /usr/share/keyrings/windsurf-stable-archive-keyring.gpg || {
    kill $repo_pid
    zenity --error --text="Failed to add Windsurf GPG key. Check internet connection." --title="Error"
    exit 1
}
echo "deb [signed-by=/usr/share/keyrings/windsurf-stable-archive-keyring.gpg arch=amd64] https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/apt stable main" | sudo tee /etc/apt/sources.list.d/windsurf.list > /dev/null || {
    kill $repo_pid
    zenity --error --text="Failed to add Windsurf repository." --title="Error"
    exit 1
}
kill $repo_pid 2>/dev/null

# Step 2: Update package list
zenity --info --text="Updating package list..." --title="Progress" --no-cancel &
update_pid=$!
sudo apt-get update -y || {
    kill $update_pid
    zenity --error --text="Update failed. Check internet or permissions." --title="Error"
    exit 1
}
kill $update_pid 2>/dev/null

# Step 3: Install Windsurf
zenity --info --text="Installing Windsurf..." --title="Progress" --no-cancel &
windsurf_pid=$!
sudo apt-get install -y windsurf || {
    kill $windsurf_pid
    zenity --error --text="Failed to install Windsurf. Repository may not be working." --title="Error"
    exit 1
}
kill $windsurf_pid 2>/dev/null

# Step 4: Modify Windsurf script for Kasm (add --no-sandbox)
zenity --info --text="Configuring Windsurf for Kasm (adding --no-sandbox)..." --title="Progress" --no-cancel &
config_pid=$!
sudo sed -i 's|ELECTRON_RUN_AS_NODE=1 "$ELECTRON" "$CLI" "$@"|ELECTRON_RUN_AS_NODE=1 "$ELECTRON" "$CLI" --no-sandbox "$@"|' /usr/share/windsurf/bin/windsurf || {
    kill $config_pid
    zenity --warning --text="Failed to modify Windsurf script. Manual fix needed." --title="Warning"
}
kill $config_pid 2>/dev/null

# Step 5: Update .desktop file to use %U
zenity --info --text="Updating Windsurf desktop file..." --title="Progress" --no-cancel &
desktop_pid=$!
sudo sed -i 's|Exec=/usr/share/windsurf/bin/windsurf %F|Exec=/usr/share/windsurf/bin/windsurf %U|' /usr/share/applications/windsurf.desktop || {
    kill $desktop_pid
    zenity --warning --text="Failed to update .desktop file. Manual fix needed." --title="Warning"
}
kill $desktop_pid 2>/dev/null

# Install additional software from user input (if provided)
if [ -n "$software_list" ]; then
    IFS=',' read -r -a software_array <<< "$software_list"
    for software in "${software_array[@]}"; do
        software=$(echo "$software" | xargs) # Trim whitespace
        if [ -n "$software" ]; then
            zenity --info --text="Installing $software..." --title="Progress" --no-cancel &
            install_pid=$!
            sudo apt-get install -y "$software" || {
                kill $install_pid
                zenity --warning --text="Failed to install $software. It might not exist or need a custom repo." --title="Warning"
            }
            kill $install_pid 2>/dev/null
        fi
    done
fi

# Success message
zenity --info --text="Installation complete!\nWindsurf and requested software installed.\nLaunch Windsurf from the menu or terminal.\nUse './install_software_gui.sh r-<software>' to remove (e.g., 'r-windsurf', 'r-makeself')." --title="Success"
