#!/bin/bash

# Exit on any error
set -e

# Colors for output (optional, makes it look nice)
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting unattended Windsurf installation...${NC}"

# Add the Windsurf GPG key
echo -e "${GREEN}Adding Windsurf GPG key...${NC}"
curl -fsSL "https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/windsurf.gpg" | sudo gpg --dearmor -o /usr/share/keyrings/windsurf-stable-archive-keyring.gpg

# Add the Windsurf APT repository
echo -e "${GREEN}Adding Windsurf APT repository...${NC}"
echo "deb [signed-by=/usr/share/keyrings/windsurf-stable-archive-keyring.gpg arch=amd64] https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/apt stable main" | sudo tee /etc/apt/sources.list.d/windsurf.list > /dev/null

# Update package list
echo -e "${GREEN}Updating package list...${NC}"
sudo apt-get update -y

# Install Windsurf
echo -e "${GREEN}Installing Windsurf...${NC}"
sudo apt-get install -y windsurf

echo -e "${GREEN}Windsurf installation complete!${NC}"
echo "You can launch Windsurf by typing 'windsurf' in the terminal."
