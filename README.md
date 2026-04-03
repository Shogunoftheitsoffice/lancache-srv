# Tyler's Lancache Master Deployment

This repository contains a zero-touch deployment script for provisioning a school Lancache server from scratch. 

## Features
* **Fully Automated Base:** Installs dependencies, Docker, and the official Lancache core.
* **Interactive Configuration:** Pauses during installation to ask for your desired cache drive size.
* **Network Auto-Configuration:** Automatically detects the server's current IP address, binds the DNS/Web containers to it, and updates the `.env` file.
* **Persistent Routing:** Injects a cron job to automatically check and update the server's IP address on every reboot.
* **Custom UI Dashboard:** Installs `cache-stats`, a custom terminal command that displays system health, CPU load, storage capacity, and live Hit/Miss cache efficiency.

## How to Deploy on a New Server

Start with a fresh Debian/Ubuntu installation. Plug the server into the network and run these two commands:

```bash
git clone [https://github.com/Shogunoftheitsoffice/lancache-srv.git](https://github.com/Shogunoftheitsoffice/lancache-srv.git)
cd lancache-srv
sudo ./install.sh
