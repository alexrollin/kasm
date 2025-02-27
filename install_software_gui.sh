#!/bin/bash

# Check if running in a graphical environment
if [ -z "$DISPLAY" ]; then
    echo "No graphical environment detected. Please run this in a GUI session (e.g., Kasm desktop)."
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
    --text="Enter a comma-separated list of additional software (e.g., fish, nano).\nWindsurf will be installed by default with Kasm fixes:" \
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
                zenity --warning --text="Failed to install $software. It might not exist." --title="Warning"
            }
            kill $install_pid 2>/dev/null
        fi
    done
fi

# Success message
zenity --info --text="Installation complete!\nWindsurf is installed and configured for Kasm.\nLaunch it from the menu or terminal." --title="Success"
