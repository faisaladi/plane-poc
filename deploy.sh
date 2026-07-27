#!/usr/bin/env bash
# ==============================================================================
# Plane Self-Host Pre-flight Check & Deployment Script
# Target OS: Ubuntu 22.04 LTS / 24.04 LTS, Debian 12, RHEL/CentOS
# ==============================================================================

set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BOLD}====================================================${NC}"
echo -e "${BOLD}      Plane Self-Host Deployment Pre-flight        ${NC}"
echo -e "${BOLD}====================================================${NC}\n"

# 1. System Resource Verification
echo -e "${BOLD}[1/4] Checking System Resources...${NC}"
TOTAL_RAM_MB=$(free -m | awk '/^Mem:/{print $2}')
CPU_CORES=$(nproc)

echo " - Detected CPU Cores: ${CPU_CORES}"
echo " - Detected RAM: ${TOTAL_RAM_MB} MB"

if [ "${TOTAL_RAM_MB}" -lt 3500 ]; then
    echo -e "${RED}[WARNING] RAM is under 4GB (${TOTAL_RAM_MB} MB). Plane runs ~10 Docker containers and may crash under load without sufficient RAM or swap space.${NC}"
    echo -e "${YELLOW}Recommendation: Add a minimum 2GB-4GB swap file before proceeding.${NC}"
else
    echo -e "${GREEN}[OK] RAM check passed.${NC}"
fi

if [ "${CPU_CORES}" -lt 2 ]; then
    echo -e "${YELLOW}[WARNING] Minimum 2 vCPUs recommended.${NC}"
else
    echo -e "${GREEN}[OK] CPU check passed.${NC}"
fi

# 2. Docker & Docker Compose Check
echo -e "\n${BOLD}[2/4] Checking Docker Engine & Docker Compose...${NC}"

if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}Docker is not installed. Installing Docker via official script...${NC}"
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
    if lsof -i :"$port" &> /dev/null || netstat -tuln | grep -q ":$port "; then
        echo -e "${YELLOW}[NOTE] Port $port is currently in use.${NC}"
    else
        echo -e "${GREEN}[OK] Port $port is available.${NC}"
    fi
}

if command -v netstat &> /dev/null || command -v lsof &> /dev/null; then
    check_port 80
    check_port 443
fi

# 4. Invoke Official Installer
echo -e "\n${BOLD}[4/4] Launching Official Plane Installer...${NC}"
echo -e "${YELLOW}This script will download Plane CLI configuration and guide interactive setup.${NC}\n"

read -p "Proceed with interactive Plane deployment? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    curl -fsSL https://prime.plane.so/install/ | sh
else
    echo -e "${YELLOW}Deployment cancelled by user. You can run 'curl -fsSL https://prime.plane.so/install/ | sh' anytime.${NC}"
fi
