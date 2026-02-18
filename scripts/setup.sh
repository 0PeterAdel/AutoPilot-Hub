#!/bin/bash
# ═══════════════════════════════════════════════════
#       AutoPilot-Hub - Initial Setup Script
# ═══════════════════════════════════════════════════

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════╗"
echo "║                                          ║"
echo "║     🤖 AutoPilot-Hub Setup               ║"
echo "║     Initial Configuration                ║"
echo "║                                          ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"

# ── Step 1: Check Prerequisites ──
echo -e "${GREEN}[1/8] Checking prerequisites...${NC}"

check_command() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}[✗] $1 is not installed!${NC}"
        echo -e "${YELLOW}    Run: ./scripts/install-dependencies.sh${NC}"
        exit 1
    else
        echo -e "${GREEN}[✓] $1 found: $(${1} --version 2>&1 | head -1)${NC}"
    fi
}

check_command docker
check_command git
check_command curl

# Check Docker Compose
if docker compose version &> /dev/null; then
    echo -e "${GREEN}[✓] Docker Compose found: $(docker compose version --short)${NC}"
else
    echo -e "${RED}[✗] Docker Compose not found!${NC}"
    exit 1
fi

# Check Docker daemon
if docker info &> /dev/null; then
    echo -e "${GREEN}[✓] Docker daemon is running${NC}"
else
    echo -e "${RED}[✗] Docker daemon is not running!${NC}"
    echo -e "${YELLOW}    Run: sudo systemctl start docker${NC}"
    exit 1
fi

# ── Step 2: Environment File ──
echo -e "\n${GREEN}[2/8] Setting up environment...${NC}"

if [ ! -f .env ]; then
    cp .env.example .env
    echo -e "${GREEN}[✓] .env file created from example${NC}"
    echo -e "${YELLOW}[!] IMPORTANT: Edit .env with your actual settings!${NC}"
    echo -e "${YELLOW}    nano .env${NC}"
else
    echo -e "${YELLOW}[!] .env already exists, skipping...${NC}"
fi

# ── Step 3: Generate Security Keys ──
echo -e "\n${GREEN}[3/8] Generating security keys...${NC}"

# Generate encryption key if not set
if grep -q "generate-a-fernet-key-here" .env 2>/dev/null; then
    FERNET_KEY=$(python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())" 2>/dev/null || echo "GENERATE_MANUALLY")
    if [ "$FERNET_KEY" != "GENERATE_MANUALLY" ]; then
        sed -i "s|generate-a-fernet-key-here|${FERNET_KEY}|g" .env
        echo -e "${GREEN}[✓] Encryption key generated${NC}"
    else
        echo -e "${YELLOW}[!] Install cryptography: pip install cryptography${NC}"
    fi
fi

# Generate secret key if not set
if grep -q "change-this-to-a-random-secret-key" .env 2>/dev/null; then
    SECRET_KEY=$(openssl rand -hex 32)
    sed -i "s|change-this-to-a-random-secret-key|${SECRET_KEY}|g" .env
    echo -e "${GREEN}[✓] Secret key generated${NC}"
fi

# ── Step 4: Create Directories ──
echo -e "\n${GREEN}[4/8] Creating directories...${NC}"

directories=(
    "data"
    "data/postgres"
    "data/redis"
    "data/rabbitmq"
    "logs"
    "reports"
    "reports/daily"
    "reports/bugs"
    "browser_data"
    "credentials"
    "backups"
)

for dir in "${directories[@]}"; do
    mkdir -p "$dir"
    echo -e "${GREEN}[✓] Created: $dir/${NC}"
done

# ── Step 5: Set Permissions ──
echo -e "\n${GREEN}[5/8] Setting permissions...${NC}"

chmod 700 credentials/
chmod 600 .env
chmod +x scripts/*.sh
echo -e "${GREEN}[✓] Permissions set${NC}"

# ── Step 6: Build Docker Images ──
echo -e "\n${GREEN}[6/8] Building Docker images...${NC}"
echo -e "${YELLOW}    This may take several minutes on first run...${NC}"

docker compose build --parallel

echo -e "${GREEN}[✓] All images built successfully${NC}"

# ── Step 7: Start Infrastructure ──
echo -e "\n${GREEN}[7/8] Starting infrastructure services...${NC}"

docker compose up -d postgres redis rabbitmq ollama

echo -e "${YELLOW}    Waiting for services to be healthy...${NC}"
sleep 15

# Check health
services=("postgres" "redis" "rabbitmq" "ollama")
for svc in "${services[@]}"; do
    container="autopilot-${svc}"
    status=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null || echo "unknown")
    if [ "$status" = "healthy" ]; then
        echo -e "${GREEN}[✓] ${svc}: healthy${NC}"
    else
        echo -e "${YELLOW}[~] ${svc}: ${status} (may still be starting)${NC}"
    fi
done

# ── Step 8: Pull Ollama Model ──
echo -e "\n${GREEN}[8/8] Pulling LLM model...${NC}"
echo -e "${YELLOW}    This will download ~4.7GB (llama3.1:8b)...${NC}"

docker exec autopilot-ollama ollama pull llama3.1:8b

echo -e "${GREEN}[✓] LLM model ready${NC}"

# ── Done ──
echo -e "\n${BLUE}"
echo "╔══════════════════════════════════════════╗"
echo "║                                          ║"
echo "║     🎉 Setup Complete!                   ║"
echo "║                                          ║"
echo "║     Next Steps:                          ║"
echo "║     1. Edit .env with your settings      ║"
echo "║     2. Run: make up                      ║"
echo "║     3. Check: make status                ║"
echo "║                                          ║"
echo "║     Infrastructure running:              ║"
echo "║     • PostgreSQL:  localhost:5432         ║"
echo "║     • Redis:       localhost:6379         ║"
echo "║     • RabbitMQ:    localhost:15672        ║"
echo "║     • Ollama:      localhost:11434        ║"
echo "║                                          ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"
