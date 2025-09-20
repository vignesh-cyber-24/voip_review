#!/bin/bash

# Quick Start Script for VoIP Security System (Kali Linux)
# This script uses the existing virtual environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🛰 VoIP Security System - Quick Start${NC}"
echo "========================================"

# Function to check if a service is running
check_service() {
    local service_name=$1
    local port=$2
    local max_attempts=15
    local attempt=1
    
    echo -e "${YELLOW}Checking $service_name on port $port...${NC}"
    
    while [ $attempt -le $max_attempts ]; do
        if nc -z localhost $port 2>/dev/null; then
            echo -e "${GREEN}✅ $service_name is running on port $port${NC}"
            return 0
        fi
        echo "Attempt $attempt/$max_attempts - waiting for $service_name..."
        sleep 2
        ((attempt++))
    done
    
    echo -e "${RED}❌ $service_name failed to start on port $port${NC}"
    return 1
}

# Function to cleanup on exit
cleanup() {
    echo -e "\n${YELLOW}🧹 Cleaning up processes...${NC}"
    
    # Kill background processes
    if [ ! -z "$IPFS_PID" ]; then
        kill $IPFS_PID 2>/dev/null || true
    fi
    if [ ! -z "$FASTAPI_PID" ]; then
        kill $FASTAPI_PID 2>/dev/null || true
    fi
    if [ ! -z "$REACT_PID" ]; then
        kill $REACT_PID 2>/dev/null || true
    fi
    if [ ! -z "$GANACHE_PID" ]; then
        kill $GANACHE_PID 2>/dev/null || true
    fi
    
    echo -e "${GREEN}✅ Cleanup completed${NC}"
}

# Set trap for cleanup on script exit
trap cleanup EXIT INT TERM

# 1. Start Ganache
echo -e "\n${BLUE}🔗 Step 1: Starting Ganache...${NC}"
if ! nc -z localhost 8545 2>/dev/null; then
    ganache --host 0.0.0.0 --port 8545 --accounts 10 --deterministic &
    GANACHE_PID=$!
    check_service "Ganache" 8545
else
    echo -e "${GREEN}✅ Ganache is already running${NC}"
fi

# 2. Start IPFS
echo -e "\n${BLUE}🌐 Step 2: Starting IPFS...${NC}"
if ! nc -z localhost 5001 2>/dev/null; then
    ipfs daemon &
    IPFS_PID=$!
    check_service "IPFS API" 5001
    check_service "IPFS Gateway" 8080
else
    echo -e "${GREEN}✅ IPFS is already running${NC}"
fi

# 3. Navigate to Blockchain directory and activate venv
echo -e "\n${BLUE}📁 Step 3: Setting up Python environment...${NC}"

# Try different possible paths for the Blockchain directory
POSSIBLE_PATHS=(
    "Voip_security-main/Blockchain"
    "Voip_security-main/Voip_security-main/Blockchain"
    "Blockchain"
    "../Blockchain"
)

BLOCKCHAIN_DIR=""
for path in "${POSSIBLE_PATHS[@]}"; do
    if [ -d "$path" ]; then
        BLOCKCHAIN_DIR="$path"
        break
    fi
done

if [ -z "$BLOCKCHAIN_DIR" ]; then
    echo -e "${RED}❌ Blockchain directory not found in any expected location${NC}"
    echo "Current directory: $(pwd)"
    echo "Please navigate to the correct directory and run the script again"
    exit 1
fi

cd "$BLOCKCHAIN_DIR"
echo "Working directory: $(pwd)"

# Check if virtual environment exists in current directory or parent
VENV_PATH=""
if [ -d "venv" ]; then
    VENV_PATH="venv"
elif [ -d "../venv" ]; then
    VENV_PATH="../venv"
elif [ -d "../../venv" ]; then
    VENV_PATH="../../venv"
fi

if [ -n "$VENV_PATH" ]; then
    echo "Found virtual environment at: $VENV_PATH"
    echo "Activating virtual environment..."
    source "$VENV_PATH/bin/activate"
    echo -e "${GREEN}✅ Virtual environment activated${NC}"
    echo "Python path: $(which python)"
else
    echo -e "${YELLOW}⚠️  Virtual environment not found. Creating new one...${NC}"
    python3 -m venv venv
    source venv/bin/activate
    echo "Installing required packages..."
    pip install fastapi uvicorn web3 requests solcx streamlit streamlit-autorefresh
    echo -e "${GREEN}✅ Virtual environment created and activated${NC}"
fi

# 4. Deploy smart contract (if needed)
echo -e "\n${BLUE}⛓️  Step 4: Checking smart contract...${NC}"
if [ ! -f "contract_address.txt" ]; then
    echo "Deploying smart contract..."
    python -c "
import sys
sys.path.append('.')
from Dashboard import *
print('Smart contract deployed successfully')
"
else
    echo -e "${GREEN}✅ Smart contract already deployed${NC}"
fi

# 5. Start FastAPI backend
echo -e "\n${BLUE}🚀 Step 5: Starting FastAPI backend...${NC}"
if [ -f "api_server.py" ]; then
    uvicorn api_server:app --host 0.0.0.0 --port 8000 --reload &
    FASTAPI_PID=$!
    check_service "FastAPI Backend" 8000
else
    echo -e "${YELLOW}⚠️  api_server.py not found. Skipping FastAPI backend${NC}"
fi

# 6. Start React Dashboard
echo -e "\n${BLUE}⚛️  Step 6: Starting React Dashboard...${NC}"
if [ -d "../react-dashboard" ]; then
    cd ../react-dashboard
    
    # Create .env if it doesn't exist
    if [ ! -f ".env" ]; then
        echo "REACT_APP_API_URL=http://localhost:8000" > .env
    fi
    
    npm start &
    REACT_PID=$!
    cd "$BLOCKCHAIN_DIR"
    check_service "React Dashboard" 3000
else
    echo -e "${YELLOW}⚠️  React dashboard not found. Starting Streamlit instead...${NC}"
    streamlit run Dashboard.py --server.port 8501 &
    check_service "Streamlit Dashboard" 8501
fi

# 7. Open browser windows
echo -e "\n${BLUE}🌐 Step 7: Opening browser windows...${NC}"
sleep 3

# Open dashboards
if [ ! -z "$REACT_PID" ]; then
    echo "Opening React Dashboard..."
    xdg-open "http://localhost:3000" 2>/dev/null || {
        echo "Please open http://localhost:3000 in your browser"
    }
fi

# Open FastAPI docs
if [ ! -z "$FASTAPI_PID" ]; then
    echo "Opening FastAPI Documentation..."
    xdg-open "http://localhost:8000/docs" 2>/dev/null || {
        echo "Please open http://localhost:8000/docs in your browser"
    }
fi

# 8. Run OnChain.py
echo -e "\n${BLUE}⛓️  Step 8: Running OnChain.py...${NC}"
if [ -f "OnChain.py" ]; then
    python OnChain.py
else
    echo -e "${YELLOW}⚠️  OnChain.py not found${NC}"
fi

# 9. System status summary
echo -e "\n${GREEN}🎉 VoIP Security System Started Successfully!${NC}"
echo "========================================"
echo -e "${BLUE}📊 System Status:${NC}"
echo "• Ganache (Blockchain): http://localhost:8545"
echo "• IPFS Gateway: http://localhost:8080"
echo "• IPFS API: http://localhost:5001"
if [ ! -z "$FASTAPI_PID" ]; then
    echo "• FastAPI Backend: http://localhost:8000"
    echo "• API Documentation: http://localhost:8000/docs"
fi
if [ ! -z "$REACT_PID" ]; then
    echo "• React Dashboard: http://localhost:3000"
fi
echo ""
echo -e "${YELLOW}💡 Tips:${NC}"
echo "• Press Ctrl+C to stop all services"
echo "• All services will be cleaned up on exit"
echo ""
echo -e "${GREEN}✅ System is ready for use!${NC}"

# Keep script running
echo -e "\n${BLUE}🔄 System is running. Press Ctrl+C to stop all services...${NC}"
while true; do
    sleep 10
done
