#!/bin/bash

# Fix and Start Script - Ensures all dependencies are installed

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Fix and Start VoIP Security System${NC}"
echo "========================================"

# Navigate to Blockchain directory
cd Voip_security-main/Blockchain

# Activate virtual environment
echo -e "\n${BLUE}🐍 Activating virtual environment...${NC}"
source venv/bin/activate
echo -e "${GREEN}✅ Virtual environment activated${NC}"

# Install missing packages
echo -e "\n${BLUE}📦 Installing/updating packages...${NC}"
pip install --upgrade pip
pip install uvicorn fastapi web3 requests solcx streamlit streamlit-autorefresh

echo -e "${GREEN}✅ All packages installed${NC}"

# Go back to main directory
cd ~/Documents/Voip_security-main

# Now run the quick start
echo -e "\n${BLUE}🚀 Starting the system...${NC}"
./quick-start.sh
