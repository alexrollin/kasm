#!/bin/bash

# How This Script Works and How to Update It:
# - Purpose: This script installs or removes software on a Kasm Ubuntu system, with a GUI for installs and CLI options for removal.
# - Usage:
#   - Install: Run './install_software_gui.sh' to launch a GUI where you type a comma-separated list of software (e.g., 'fish, nano, windsurf'). Only listed software is installed; 'windsurf' gets Kasm fixes, 'fish' gets lazy tweaks.
#   - Remove: Run './install_software_gui.sh r-<software>' to remove a specific software (e.g., './install_software_gui.sh r-windsurf').
# - Structure:
#   - Removal functions (e.g., remove_windsurf) are defined first. Add new ones for each software following the same pattern.
#   - A CLI check (if [ "$1" = "r-<software>" ]) triggers the matching removal function.
#   - If no CLI arg, it runs the GUI install process based on user input only.
# - Updating for New Software:
#   1. Add a 'remove_<software>()' function with uninstall steps (e.g., 'sudo apt purge -y <software>', config cleanup).
#   2. Add an 'if [ "$1" = "r-<software>" ]' check below existing ones to call the new function.
#   3. In the GUI install loop, add custom install/configure steps for the new software (e.g., repo setup, tweaks).
#   4. Update the Zenity prompt to list the new software as an option.

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Trap to clean up any lingering Zenity processes on exit
trap 'pkill -u $USER zenity 2>/dev/null' EXIT

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
    zenity --info --text="Zenity not found. Installing it first..." --title="Setup"
    sudo apt update -y && sudo apt install -y zenity || {
        zenity --error --text="Failed to install Zenity. Exiting." --title="Error"
        exit 1
    }
fi

# Prompt user for software list via GUI
software_list=$(zenity --entry \
    --title="Software Installer" \
    --text="Enter a comma-separated list of software to install (e.g., fish, nano, windsurf, makeself).\n'windsurf' gets Kasm fixes, 'fish' gets lazy tweaks.\nUse './install_software_gui.sh r-<software>' to remove (e.g., 'r-windsurf', 'r-makeself')." \
    --width=400)

# Exit if canceled or empty
if [ $? -ne 0 ] || [ -z "$software_list" ]; then
    zenity --error --text="No software specified or canceled. Exiting." --title="Error"
    exit 1
fi

# Install software from user input
IFS=',' read -r -a software_array <<< "$software_list"
for software in "${software_array[@]}"; do
    software=$(echo "$software" | xargs) # Trim whitespace
    if [ -n "$software" ]; then
        zenity --info --text="Processing $software..." --title="Progress"

        # Special handling for Windsurf
        if [ "$software" = "windsurf" ]; then
            zenity --info --text="Setting up Windsurf repository..." --title="Progress"
            curl -fsSL "https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/windsurf.gpg" | sudo gpg --dearmor -o /usr/share/keyrings/windsurf-stable-archive-keyring.gpg || {
                zenity --error --text="Failed to add Windsurf GPG key." --title="Error"
                exit 1
            }
            echo "deb [signed-by=/usr/share/keyrings/windsurf-stable-archive-keyring.gpg arch=amd64] https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/apt stable main" | sudo tee /etc/apt/sources.list.d/windsurf.list > /dev/null || {
                zenity --error --text="Failed to add Windsurf repository." --title="Error"
                exit 1
            }
            sudo apt-get update -y || {
                zenity --error --text="APT update failed for Windsurf." --title="Error"
                exit 1
            }
            zenity --info --text="Installing Windsurf..." --title="Progress"
            sudo apt-get install -y windsurf || {
                zenity --warning --text="Failed to install Windsurf." --title="Warning"
            }
            zenity --info --text="Configuring Windsurf for Kasm..." --title="Progress"
            sudo sed -i 's|ELECTRON_RUN_AS_NODE=1 "$ELECTRON" "$CLI" "$@"|ELECTRON_RUN_AS_NODE=1 "$ELECTRON" "$CLI" --no-sandbox "$@"|' /usr/share/windsurf/bin/windsurf || {
                zenity --warning --text="Failed to modify Windsurf script." --title="Warning"
            }
            sudo sed -i 's|Exec=/usr/share/windsurf/bin/windsurf %F|Exec=/usr/share/windsurf/bin/windsurf %U|' /usr/share/applications/windsurf.desktop || {
                zenity --warning --text="Failed to update Windsurf .desktop file." --title="Warning"
            }
        else
            # Install other software
            zenity --info --text="Installing $software..." --title="Progress"
            sudo apt-get install -y "$software" || {
                zenity --warning --text="Failed to install $software. It might not exist or need a custom repo." --title="Warning"
            }

            # Special handling for Fish enhancements
            if [ "$software" = "fish" ]; then
                zenity --info --text="Enhancing Fish with lazy tweaks..." --title="Progress"
                sudo apt-get install -y xclip xsel fzf || echo -e "${RED}Failed to install Fish dependencies.${NC}"
                sudo chsh -s /usr/bin/fish || echo -e "${RED}Failed to set Fish as default shell.${NC}"
                mkdir -p /root/.config/fish
                cat << 'EOF' > /root/.config/fish/config.fish
# Force instant paste
bind \cv 'commandline -i (pbpaste 2>/dev/null || xclip -o 2>/dev/null || xsel -o 2>/dev/null)'

# Enhance completions
complete -c '' -f -a '(find /root /home/kasm-user /usr/bin -maxdepth 1 -type f -executable)' --description 'All executables'
set -g fish_autosuggestion_delay 100

# Lazy aliases
alias i='apt install -y'
alias r='apt purge -y'
alias u='apt update && apt upgrade -y'
alias ls='ls -lh'
alias cd..='cd ..'

# Simple prompt
function fish_prompt
    set_color green
    echo -n "root@$(hostname):"
    set_color blue
    echo -n (basename $PWD)
    set_color normal
    echo -n '$ '
end

# Fuzzy finder
set -gx FZF_DEFAULT_OPTS '--height 40% --layout=reverse'
bind \cf 'fzf | read -l result; and commandline -i $result'

# No greeting
set fish_greeting ""
EOF
                if [ -f /root/.config/fish/config.fish ]; then
                    zenity --info --text="Fish enhanced successfully!" --title="Progress"
                else
                    zenity --warning --text="Failed to write Fish config." --title="Warning"
                fi
            fi
        fi
    fi
done

# Success message
zenity --info --text="Installation complete!\nRequested software installed.\nIf Windsurf was included, it’s configured for Kasm.\nIf Fish was included, it’s enhanced for laziness.\nUse './install_software_gui.sh r-<software>' to remove." --title="Success"
