#!/bin/bash

# Check if Zenity is installed
if ! command -v zenity &> /dev/null; then
    echo "Zenity not found. Installing it first..."
    sudo apt update -y && sudo apt install -y zenity || { echo "Failed to install Zenity. Exiting."; exit 1; }
fi

# Prompt user for software list via GUI
software_list=$(zenity --entry \
    --title="Software Installer" \
    --text="Enter a comma-separated list of software to install (e.g., windsurf, fish, nano):" \
    --width=400)

# Exit if canceled or empty
if [ $? -ne 0 ] || [ -z "$software_list" ]; then
    zenity --error --text="No software specified or canceled. Exiting." --title="Error"
    exit 1
fi

# Convert comma-separated list to array
IFS=',' read -r -a software_array <<< "$software_list"

# Update package list
zenity --info --text="Updating package list..." --title="Progress" --no-cancel &
update_pid=$!
sudo apt update -y || { kill $update_pid; zenity --error --text="Update failed. Check internet or permissions." --title="Error"; exit 1; }
kill $update_pid

# Install each software item
for software in "${software_array[@]}"; do
    # Trim whitespace
    software=$(echo "$software" | xargs)
    if [ -n "$software" ]; then
        zenity --info --text="Installing $software..." --title="Progress" --no-cancel &
        install_pid=$!
        sudo apt install -y "$software" || zenity --warning --text="Failed to install $software. It might not exist or need a repository." --title="Warning"
        kill $install_pid 2>/dev/null
    fi
done

# Success message
zenity --info --text="Installation complete!" --title="Success"
