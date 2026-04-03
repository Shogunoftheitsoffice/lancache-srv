#!/bin/bash

echo ">>> INITIATING PROJECT: LANCACHE MASTER BUILD <<<"

# --- THE MAGIC FIX: DYNAMIC USER DETECTION ---
# Find out who actually ran the script (even if they used 'sudo')
ACTUAL_USER=${SUDO_USER:-$USER}
# Find that user's true home directory
ACTUAL_HOME=$(getent passwd "$ACTUAL_USER" | cut -d: -f6)
# Define the master Lancache directory
LANCACHE_DIR="$ACTUAL_HOME/lancache"

echo ">>> Detected user: $ACTUAL_USER"
echo ">>> Target directory: $LANCACHE_DIR"
echo "---------------------------------------------------"

# 1. Install System Dependencies & Docker
echo ">>> Step 1: Installing Dependencies & Docker..."
sudo apt-get update
sudo apt-get install -y curl git jq
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
else
    echo "Docker is already installed. Skipping."
fi

# 2. Download the Official Lancache Base
echo ">>> Step 2: Downloading Lancache Core..."
if [ ! -d "$LANCACHE_DIR" ]; then
    # We force git to download as the actual user, so the folder permissions don't break
    sudo -u "$ACTUAL_USER" git clone https://github.com/lancachenet/docker-compose.git "$LANCACHE_DIR"
    cd "$LANCACHE_DIR"
    sudo -u "$ACTUAL_USER" cp .env.example .env
else
    echo "Lancache directory already exists. Skipping clone."
fi

# 2.5 The Interactive Storage Prompt
echo ""
echo "---------------------------------------------------"
echo ">>> STORAGE CONFIGURATION <<<"
echo "---------------------------------------------------"
read -p "How much storage space should be dedicated to games? (e.g., 500g, 1000g, 2t): " CACHE_SIZE

# Replace the default CACHE_DISK_SIZE with the user's input
sed -i "s/^CACHE_DISK_SIZE=.*/CACHE_DISK_SIZE=${CACHE_SIZE}/" "$LANCACHE_DIR/.env"
echo "Success: Cache size locked in at ${CACHE_SIZE}."
echo "---------------------------------------------------"
echo ""

# 3. Install Custom Mods with Dynamic Paths
echo ">>> Step 3: Adapting and Installing Custom Tools..."
cd "$(dirname "$0")" # Ensure we are in the cloned repo folder

# Find every instance of "/home/tyler/lancache" in your scripts and replace it with the new path
sed -i "s|/home/tyler/lancache|$LANCACHE_DIR|g" cache-stats
sed -i "s|/home/tyler/lancache|$LANCACHE_DIR|g" update-cache-ip

sudo cp cache-stats /usr/local/bin/
sudo cp update-cache-ip /usr/local/bin/
sudo chmod +x /usr/local/bin/cache-stats
sudo chmod +x /usr/local/bin/update-cache-ip

# 4. Configure Boot Sequence (Crontab)
echo ">>> Step 4: Configuring Auto-IP Boot Sequence..."
CRON_JOB="@reboot sleep 15 && /usr/local/bin/update-cache-ip > /var/log/lancache-ip-update.log 2>&1"
sudo crontab -l 2>/dev/null | grep -F "$CRON_JOB" > /dev/null
if [ $? -eq 0 ]; then
    echo "Cronjob already exists. Skipping."
else
    (sudo crontab -l 2>/dev/null; echo "$CRON_JOB") | sudo crontab -
fi

# 5. Auto-Configure IP and Boot
echo ">>> Step 5: Configuring Network and Starting Server..."
sudo /usr/local/bin/update-cache-ip

echo "==================================================="
echo " INSTALLATION COMPLETE! "
echo " Type 'cache-stats' to view your dashboard."
echo "==================================================="
