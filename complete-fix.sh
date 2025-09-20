#!/bin/bash

# Complete Fix Script - Installs all dependencies and starts the system

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Complete Fix for VoIP Security System${NC}"
echo "========================================"

# Navigate to Blockchain directory
echo -e "\n${BLUE}📁 Navigating to Blockchain directory...${NC}"
cd Voip_security-main/Blockchain

# Activate virtual environment
echo -e "\n${BLUE}🐍 Activating virtual environment...${NC}"
source venv/bin/activate
echo -e "${GREEN}✅ Virtual environment activated${NC}"
echo "Python path: $(which python)"
echo "Pip path: $(which pip)"

# Upgrade pip first
echo -e "\n${BLUE}⬆️  Upgrading pip...${NC}"
pip install --upgrade pip

# Install all required packages
echo -e "\n${BLUE}📦 Installing all required packages...${NC}"
pip install \
    fastapi>=0.104.0 \
    uvicorn[standard]>=0.24.0 \
    web3>=6.11.0 \
    py-solc-x>=1.12.0 \
    requests>=2.31.0 \
    streamlit>=1.28.0 \
    streamlit-autorefresh>=0.0.1 \
    pandas>=2.1.0 \
    cryptography>=41.0.0 \
    python-multipart>=0.0.6 \
    python-dotenv>=1.0.0

echo -e "${GREEN}✅ All packages installed successfully${NC}"

# Verify critical packages
echo -e "\n${BLUE}🔍 Verifying package installation...${NC}"
python -c "import fastapi; print(f'FastAPI: {fastapi.__version__}')"
python -c "import uvicorn; print(f'Uvicorn: {uvicorn.__version__}')"
python -c "import requests; print(f'Requests: {requests.__version__}')"
python -c "import web3; print(f'Web3: {web3.__version__}')"
python -c "import solcx; print(f'Solcx: {solcx.__version__}')"

echo -e "${GREEN}✅ All packages verified${NC}"

# Test the API server import
echo -e "\n${BLUE}🧪 Testing API server import...${NC}"
python -c "
try:
    import sys
    sys.path.append('.')
    import api_server
    print('✅ API server imports successfully')
except Exception as e:
    print(f'❌ API server import failed: {e}')
    exit(1)
"

# Go back to main directory
cd ~/Documents/Voip_security-main

# Kill any existing processes on the ports we need
echo -e "\n${BLUE}🧹 Cleaning up existing processes...${NC}"
pkill -f "ganache" 2>/dev/null || true
pkill -f "ipfs" 2>/dev/null || true
pkill -f "uvicorn" 2>/dev/null || true
pkill -f "streamlit" 2>/dev/null || true
pkill -f "npm start" 2>/dev/null || true
sleep 2

# Now run the quick start
echo -e "\n${BLUE}🚀 Starting the system...${NC}"
./quick-start.sh
