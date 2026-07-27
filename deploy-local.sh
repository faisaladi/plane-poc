#!/usr/bin/env bash
# ==============================================================================
# Plane Self-Host Local Deployment Script (macOS / Linux Local Docker)
# ==============================================================================

set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BOLD}====================================================${NC}"
echo -e "${BOLD}         Plane Self-Host Local Setup                ${NC}"
echo -e "${BOLD}====================================================${NC}\n"

# 1. Check Docker & Docker Compose
echo -e "${BOLD}[1/3] Checking Local Docker Engine...${NC}"
if ! docker info &> /dev/null; then
    echo -e "${RED}[ERROR] Docker is not running on your local machine.${NC}"
    echo -e "${YELLOW}Please start Docker Desktop / OrbStack / Docker Daemon first, then re-run this script.${NC}"
    exit 1
fi
echo -e "${GREEN}[OK] Docker engine is running: $(docker --version)${NC}"

# 2. Check Port 80 availability
echo -e "\n${BOLD}[2/3] Checking Port Availability (Port 80)...${NC}"
if lsof -i :80 &> /dev/null || nc -z localhost 80 &> /dev/null; then
    echo -e "${YELLOW}[NOTE] Port 80 is occupied. Plane web proxy will bind to http://localhost:80.${NC}"
    echo -e "${YELLOW}If you have Apache/Nginx running locally on port 80, stop it or update WEB_URL in .env${NC}"
else
    echo -e "${GREEN}[OK] Port 80 is available.${NC}"
fi

# 3. Create .env from template if missing
if [ ! -f ".env" ]; then
    echo -e "\n${BOLD}[3/3] Generating local .env configuration...${NC}"
    cp .env.example .env
    # Set WEB_URL to local host
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' 's|WEB_URL=https://plane.yourcompany.com|WEB_URL=http://localhost|g' .env
    else
        sed -i 's|WEB_URL=https://plane.yourcompany.com|WEB_URL=http://localhost|g' .env
    fi
    echo -e "${GREEN}[OK] Created .env with WEB_URL=http://localhost${NC}"
else
    echo -e "\n${BOLD}[3/3] Using existing .env file.${NC}"
fi

echo -e "\n${BOLD}Starting Plane local services via Docker Compose...${NC}"
docker compose up -d

echo -e "\n${BOLD}====================================================${NC}"
echo -e "${GREEN}${BOLD}🎉 Plane is starting up locally!${NC}"
echo -e "${BOLD}====================================================${NC}"
echo -e " - Main Application UI: ${BOLD}http://localhost${NC}"
echo -e " - Instance Setup / Admin: ${BOLD}http://localhost/god-mode/${NC}"
echo -e " - MinIO Storage Console: ${BOLD}http://localhost:9001${NC}"
echo -e "\n${YELLOW}Note: It may take 1-2 minutes for PostgreSQL and database migrations to complete.${NC}"
echo -e "Check logs anytime with: ${BOLD}docker compose logs -f${NC}\n"
