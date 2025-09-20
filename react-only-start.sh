#!/bin/bash

# React-Only VoIP Security System Startup (NO STREAMLIT!)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🛰 VoIP Security System - React Dashboard Only${NC}"
echo "========================================"
echo -e "${GREEN}✅ Using React.js dashboard (NO Streamlit!)${NC}"

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

# 3. Setup Python environment (minimal - no Streamlit!)
echo -e "\n${BLUE}📁 Step 3: Setting up Python environment...${NC}"

# Try different possible paths for the Blockchain directory
POSSIBLE_PATHS=(
    "Voip_security-main/Blockchain"
    "Voip_security-main/Voip_security-main/Blockchain"
    "Blockchain"
)

BLOCKCHAIN_DIR=""
for path in "${POSSIBLE_PATHS[@]}"; do
    if [ -d "$path" ]; then
        BLOCKCHAIN_DIR="$path"
        break
    fi
done

if [ -z "$BLOCKCHAIN_DIR" ]; then
    echo -e "${RED}❌ Blockchain directory not found${NC}"
    echo "Current directory: $(pwd)"
    echo "Available directories:"
    ls -la
    exit 1
fi

cd "$BLOCKCHAIN_DIR"
echo "Working directory: $(pwd)"

# Look for virtual environment in multiple locations
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
    echo -e "${YELLOW}⚠️  No virtual environment found. Creating new one...${NC}"
    python3 -m venv venv
    source venv/bin/activate
    echo -e "${GREEN}✅ New virtual environment created and activated${NC}"
fi

# Install only what we need (NO STREAMLIT!)
echo "Installing minimal Python packages..."
pip install --upgrade pip
pip install fastapi uvicorn requests web3 python-multipart python-dotenv

echo -e "${GREEN}✅ Python environment ready${NC}"

# 4. Start FastAPI backend
echo -e "\n${BLUE}🚀 Step 4: Starting FastAPI backend...${NC}"
if [ -f "api_server.py" ]; then
    uvicorn api_server:app --host 0.0.0.0 --port 8000 --reload &
    FASTAPI_PID=$!
    check_service "FastAPI Backend" 8000
else
    echo -e "${YELLOW}⚠️  api_server.py not found${NC}"
fi

# 5. Start React Dashboard (ONLY React, NO Streamlit!)
echo -e "\n${BLUE}⚛️  Step 5: Starting React Dashboard...${NC}"

# Go back to main directory to find react-dashboard
cd ~/Documents/Voip_security-main

# Look for React dashboard in multiple possible locations
REACT_PATHS=(
    "react-dashboard"
    "../react-dashboard"
    "Voip_security-main/react-dashboard"
)

REACT_DIR=""
for path in "${REACT_PATHS[@]}"; do
    if [ -d "$path" ]; then
        REACT_DIR="$path"
        break
    fi
done

if [ -n "$REACT_DIR" ]; then
    echo -e "${GREEN}✅ Found React dashboard at: $REACT_DIR${NC}"
    cd "$REACT_DIR"

    # Create .env if it doesn't exist
    if [ ! -f ".env" ]; then
        echo "REACT_APP_API_URL=http://localhost:8000" > .env
        echo -e "${GREEN}✅ Created .env file${NC}"
    fi

    # Install dependencies if node_modules doesn't exist
    if [ ! -d "node_modules" ]; then
        echo -e "${BLUE}📦 Installing React dependencies...${NC}"
        npm install
    fi

    echo -e "${GREEN}🚀 Starting React development server...${NC}"
    npm start &
    REACT_PID=$!

    # Go back to blockchain directory
    cd ~/Documents/Voip_security-main/"$BLOCKCHAIN_DIR"
    check_service "React Dashboard" 3000
else
    echo -e "${RED}❌ React dashboard not found in any expected location${NC}"
    echo "Searched in:"
    for path in "${REACT_PATHS[@]}"; do
        echo "  - $path"
    done
    echo "Please ensure the React dashboard is properly set up"
    exit 1
fi

# 6. Open browser windows
echo -e "\n${BLUE}🌐 Step 6: Opening browser windows...${NC}"
sleep 3

echo "Opening React Dashboard..."
xdg-open "http://localhost:3000" 2>/dev/null || {
    echo "Please open http://localhost:3000 in your browser"
}

if [ ! -z "$FASTAPI_PID" ]; then
    echo "Opening FastAPI Documentation..."
    xdg-open "http://localhost:8000/docs" 2>/dev/null || {
        echo "Please open http://localhost:8000/docs in your browser"
    }
fi

# 7. System status summary
echo -e "\n${GREEN}🎉 React-Only VoIP Security System Started!${NC}"
echo "========================================"
echo -e "${BLUE}📊 System Status:${NC}"
echo "• Ganache (Blockchain): http://localhost:8545"
echo "• IPFS Gateway: http://localhost:8080"
echo "• IPFS API: http://localhost:5001"
if [ ! -z "$FASTAPI_PID" ]; then
    echo "• FastAPI Backend: http://localhost:8000"
    echo "• API Documentation: http://localhost:8000/docs"
fi
echo "• React Dashboard: http://localhost:3000"
echo ""
echo -e "${GREEN}✅ Modern React.js dashboard is running!${NC}"
echo -e "${RED}❌ NO Streamlit (as requested)${NC}"
echo ""
echo -e "${YELLOW}💡 Tips:${NC}"
echo "• Press Ctrl+C to stop all services"
echo "• React dashboard auto-refreshes every 5 seconds"
echo "• All CDR data is displayed in the modern React UI"

# Keep script running
echo -e "\n${BLUE}🔄 System is running. Press Ctrl+C to stop all services...${NC}"
while true; do
    sleep 10
done
