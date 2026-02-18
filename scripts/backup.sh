#!/bin/bash
# ═══════════════════════════════════════════════════
#       AutoPilot-Hub - Backup Script
# ═══════════════════════════════════════════════════

set -e

GREEN='\033[0;32m'
NC='\033[0m'

BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="${BACKUP_DIR}/backup_${TIMESTAMP}"

mkdir -p "$BACKUP_PATH"

echo -e "${GREEN}[+] Starting backup: ${TIMESTAMP}${NC}"

# Backup PostgreSQL
echo -e "${GREEN}[+] Backing up PostgreSQL...${NC}"
docker exec autopilot-postgres pg_dump \
    -U ${POSTGRES_USER:-autopilot} \
    -d ${POSTGRES_DB:-autopilot_hub} \
    > "${BACKUP_PATH}/database.sql"

# Backup .env
echo -e "${GREEN}[+] Backing up configuration...${NC}"
cp .env "${BACKUP_PATH}/.env.backup"

# Backup Redis
echo -e "${GREEN}[+] Backing up Redis...${NC}"
docker exec autopilot-redis redis-cli \
    -a ${REDIS_PASSWORD} BGSAVE
sleep 2
docker cp autopilot-redis:/data/dump.rdb \
    "${BACKUP_PATH}/redis-dump.rdb" 2>/dev/null || true

# Compress
echo -e "${GREEN}[+] Compressing backup...${NC}"
tar -czf "${BACKUP_DIR}/backup_${TIMESTAMP}.tar.gz" \
    -C "$BACKUP_DIR" "backup_${TIMESTAMP}"
rm -rf "$BACKUP_PATH"

# Keep only last 7 backups
echo -e "${GREEN}[+] Cleaning old backups (keeping last 7)...${NC}"
ls -t ${BACKUP_DIR}/backup_*.tar.gz 2>/dev/null | \
    tail -n +8 | xargs rm -f 2>/dev/null || true

echo -e "${GREEN}[✓] Backup complete: backup_${TIMESTAMP}.tar.gz${NC}"
