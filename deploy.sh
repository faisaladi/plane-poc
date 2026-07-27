#!/usr/bin/env bash
# ==============================================================================
# Plane Self-Host Unified Production Deployment Script (VPS / Tencent Cloud)
# Target OS: Ubuntu 22.04 / 24.04 LTS, Debian 12
# ==============================================================================

set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BOLD}====================================================${NC}"
echo -e "${BOLD}     Plane Self-Host Unified Production Setup       ${NC}"
echo -e "${BOLD}====================================================${NC}\n"

# 1. System Resource Verification
echo -e "${BOLD}[1/4] Checking System Resources...${NC}"
TOTAL_RAM_MB=$(free -m | awk '/^Mem:/{print $2}')
CPU_CORES=$(nproc)

echo " - Detected CPU Cores: ${CPU_CORES}"
echo " - Detected RAM: ${TOTAL_RAM_MB} MB"

if [ "${TOTAL_RAM_MB}" -lt 3500 ]; then
    echo -e "${RED}[WARNING] System RAM is under 4GB (${TOTAL_RAM_MB} MB).${NC}"
    echo -e "${YELLOW}Plane runs 12 Docker containers. Ensure a 2GB-4GB swap file is enabled to avoid OOM errors.${NC}"
else
    echo -e "${GREEN}[OK] System RAM check passed.${NC}"
fi

if [ "${CPU_CORES}" -lt 2 ]; then
    echo -e "${YELLOW}[WARNING] Minimum 2 vCPUs recommended.${NC}"
else
    echo -e "${GREEN}[OK] CPU Cores check passed.${NC}"
fi

# 2. Docker & Docker Compose Check
echo -e "\n${BOLD}[2/4] Checking Docker Engine & Docker Compose...${NC}"

if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}Docker is not installed. Installing Docker via official get.docker.com script...${NC}"
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker "$USER" || true
    echo -e "${GREEN}Docker installed successfully.${NC}"
else
    echo -e "${GREEN}[OK] Docker is installed: $(docker --version)${NC}"
fi

if ! docker compose version &> /dev/null; then
    echo -e "${RED}[ERROR] Docker Compose plugin (v2+) is required.${NC}"
    echo "Install via: sudo apt-get install docker-compose-plugin"
    exit 1
else
    echo -e "${GREEN}[OK] Docker Compose is installed: $(docker compose version)${NC}"
fi

# 3. Network Ports Check
echo -e "\n${BOLD}[3/4] Checking Required Ports (80, 443)...${NC}"
check_port() {
    local port=$1
    if command -v lsof &> /dev/null && lsof -i :"$port" &> /dev/null; then
        echo -e "${YELLOW}[NOTE] Port $port is currently in use.${NC}"
    else
        echo -e "${GREEN}[OK] Port $port is available.${NC}"
    fi
}
check_port 80
check_port 443

# 4. Environment Configuration
echo -e "\n${BOLD}[4/4] Verifying Environment Configuration (.env)...${NC}"
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}Creating .env from .env.example template...${NC}"
    cp .env.example .env
    echo -e "${GREEN}[OK] Created .env file.${NC}"
    echo -e "${RED}${BOLD}[ACTION REQUIRED] Please review and update .env with your domain (WEB_URL) and production secrets!${NC}"
else
    echo -e "${GREEN}[OK] Existing .env file found.${NC}"
fi

# 5. Launch Containers via Docker Compose
echo -e "\n${BOLD}Starting Plane production stack via Docker Compose...${NC}"
docker compose up -d

echo -e "\n${BOLD}====================================================${NC}"
echo -e "${GREEN}${BOLD}🎉 Plane production stack started successfully!${NC}"
echo -e "${BOLD}====================================================${NC}"
echo -e " - Instance Setup / God Mode: ${BOLD}http://<YOUR_SERVER_IP_OR_DOMAIN>/god-mode/${NC}"
echo -e " - Main Application UI: ${BOLD}http://<YOUR_SERVER_IP_OR_DOMAIN>/${NC}"
echo -e "\n${YELLOW}Note: First-time database migrations run automatically via 'plane-migrator' and take ~1-2 minutes to complete.${NC}"
echo -e "Check logs anytime with: ${BOLD}docker compose logs -f${NC}\n"
