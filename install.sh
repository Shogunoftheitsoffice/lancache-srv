#!/bin/bash

echo ">>> INITIATING PROJECT: TYLER'S LANCACHE MASTER BUILD <<<"

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
if [ ! -d "$HOME/lancache" ]; then
    git clone https://github.com/lancachenet/docker-compose.git "$HOME/lancache"
    cd "$HOME/lancache"
    # Create the .env file from the template
    cp .env.example .env
else
    echo "Lancache directory already exists. Skipping clone."
fi

# 2.5 The Interactive Storage Prompt
echo ""
echo "---------------------------------------------------"
echo ">>> STORAGE CONFIGURATION <<<"
echo "---------------------------------------------------"
# Ask the user for the cache size and store it in a variable called CACHE_SIZE
read -p "How much storage space should be dedicated to games? (e.g., 500g, 1000g, 2t): " CACHE_SIZE

# Replace the default CACHE_DISK_SIZE in the .env file with the user's input
sed -i "s/^CACHE_DISK_SIZE=.*/CACHE_DISK_SIZE=${CACHE_SIZE}/" "$HOME/lancache/.env"
echo "Success: Cache size locked in at ${CACHE_SIZE}."
echo "---------------------------------------------------"
echo ""

# 3. Install Tyler's Custom Mods
echo ">>> Step 3: Installing Custom Tools..."
cd "$(dirname "$0")" # Ensure we are in the repo folder
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
# We run your custom IP updater right now so it instantly writes the server's IP into the fresh .env file!
sudo /usr/local/bin/update-cache-ip

echo "==================================================="
echo " INSTALLATION COMPLETE! "
echo " Type 'cache-stats' to view your dashboard."
echo "==================================================="
