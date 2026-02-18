#!/bin/bash
# ═══════════════════════════════════════════════════
#       AutoPilot-Hub - Health Check Script
# ═══════════════════════════════════════════════════

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║     🏥 AutoPilot-Hub Health Check        ║"
echo "╚══════════════════════════════════════════╝"
echo ""

check_service() {
    local name=$1
    local url=$2
    local container=$3

    # Check if container is running
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        # Check HTTP health endpoint
        if [ -n "$url" ]; then
            status_code=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
            if [ "$status_code" = "200" ]; then
                echo -e "  ${GREEN}✅ ${name}: HEALTHY (HTTP ${status_code})${NC}"
            else
                echo -e "  ${YELLOW}⚠️  ${name}: DEGRADED (HTTP ${status_code})${NC}"
            fi
        else
            echo -e "  ${GREEN}✅ ${name}: RUNNING${NC}"
        fi
    else
        echo -e "  ${RED}❌ ${name}: DOWN${NC}"
    fi
}

echo "── Infrastructure ──"
check_service "PostgreSQL" "" "autopilot-postgres"
check_service "Redis" "" "autopilot-redis"
check_service "RabbitMQ" "http://localhost:15672" "autopilot-rabbitmq"
check_service "Ollama" "http://localhost:11434" "autopilot-ollama"

echo ""
echo "── Application ──"
check_service "Main Agent" "http://localhost:8000/health" "autopilot-main-agent"
check_service "Freelancer" "http://localhost:8001/health" "autopilot-freelancer"
check_service "Email" "http://localhost:8002/health" "autopilot-email"
check_service "DevEnv" "http://localhost:8003/health" "autopilot-devenv"
check_service "BugHunter" "http://localhost:8004/health" "autopilot-bughunter"
check_service "Telegram" "" "autopilot-telegram"
check_service "Dashboard" "http://localhost:8080" "autopilot-dashboard"

echo ""
echo "── Resources ──"
echo "  📊 Docker Stats:"
docker stats --no-stream --format \
    "  {{.Name}}: CPU={{.CPUPerc}} MEM={{.MemUsage}}" \
    2>/dev/null | head -15

echo ""
echo "  💾 Disk Usage:"
echo "  $(df -h / | tail -1 | awk '{print "Used: "$3" / "$2" ("$5")"}')"
echo "  Docker: $(docker system df --format '{{.Size}}' 2>/dev/null | head -1)"
echo ""
