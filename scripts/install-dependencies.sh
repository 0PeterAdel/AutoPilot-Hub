#!/bin/bash
# ═══════════════════════════════════════════════════
#    AutoPilot-Hub - System Dependencies Installation
#    Supported: Ubuntu 22.04 LTS / Debian 12
# ═══════════════════════════════════════════════════

set -e

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}[+] Updating system packages...${NC}"
sudo apt update && sudo apt upgrade -y

echo -e "${GREEN}[+] Installing base packages...${NC}"
sudo apt install -y \
    curl \
    wget \
    git \
    vim \
    htop \
    tmux \
    unzip \
    jq \
    tree \
    net-tools \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    build-essential \
    openssl

# ── Docker ──
echo -e "${GREEN}[+] Installing Docker...${NC}"
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    rm get-docker.sh
    sudo usermod -aG docker $USER
    echo -e "${GREEN}[✓] Docker installed${NC}"
    echo -e "${YELLOW}[!] Log out and back in for docker group to take effect${NC}"
else
    echo -e "${YELLOW}[!] Docker already installed${NC}"
fi

# ── Python 3.11+ ──
echo -e "${GREEN}[+] Installing Python 3.11...${NC}"
sudo add-apt-repository ppa:deadsnakes/ppa -y
sudo apt update
sudo apt install -y \
    python3.11 \
    python3.11-venv \
    python3.11-dev \
    python3-pip

# ── pip packages (for setup scripts) ──
echo -e "${GREEN}[+] Installing Python utilities...${NC}"
pip3 install --user \
    cryptography \
    python-dotenv

# ── Security ──
echo -e "${GREEN}[+] Installing security tools...${NC}"
sudo apt install -y \
    fail2ban \
    ufw

# Setup basic firewall
echo -e "${GREEN}[+] Configuring firewall...${NC}"
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 8000:8080/tcp  # Application ports
sudo ufw allow 3000/tcp       # Grafana
sudo ufw --force enable

echo -e "${GREEN}"
echo "╔══════════════════════════════════════════╗"
echo "║   [✓] All dependencies installed!        ║"
echo "║                                          ║"
echo "║   Installed:                             ║"
echo "║   • Docker + Docker Compose              ║"
echo "║   • Python 3.11                          ║"
echo "║   • Security tools (ufw, fail2ban)       ║"
echo "║   • Utility tools                        ║"
echo "║                                          ║"
echo "║   Next: ./scripts/setup.sh               ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"
