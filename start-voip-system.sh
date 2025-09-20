#!/bin/bash

# VoIP Security System - Complete Startup Script
# This script starts all components of the VoIP CDR Blockchain + IPFS system

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log file
LOG_FILE="voip_system_startup.log"
exec > >(tee -a "$LOG_FILE")
exec 2>&1

echo -e "${BLUE}🛰 VoIP Security System Startup${NC}"
echo "========================================"
echo "Starting all components..."
echo "Log file: $LOG_FILE"
echo ""

# Function to check if a service is running
check_service() {
    local service_name=$1
    local port=$2
    local max_attempts=30
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
    if [ ! -z "$STREAMLIT_PID" ]; then
        kill $STREAMLIT_PID 2>/dev/null || true
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

# Check prerequisites
echo -e "${BLUE}📋 Checking prerequisites...${NC}"

# Check if running as root for Asterisk
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}⚠️  Note: You may need sudo privileges for Asterisk${NC}"
fi

# Check required commands
REQUIRED_COMMANDS=("python3" "node" "npm")
for cmd in "${REQUIRED_COMMANDS[@]}"; do
    if ! command -v $cmd &> /dev/null; then
        echo -e "${RED}❌ $cmd is not installed${NC}"
        exit 1
    fi
done

echo -e "${GREEN}✅ Prerequisites check passed${NC}"
echo ""

# 1. Start Ganache (if available)
echo -e "${BLUE}🔗 Step 1: Starting Ganache (Blockchain)...${NC}"
if command -v ganache &> /dev/null; then
    ganache --host 0.0.0.0 --port 8545 --accounts 10 --deterministic &
    GANACHE_PID=$!
    check_service "Ganache" 8545
else
    echo -e "${YELLOW}⚠️  Ganache not found. Please start it manually or install ganache-cli${NC}"
    echo "   npm install -g ganache-cli"
    echo "   Then run: ganache --host 0.0.0.0 --port 8545"
    read -p "Press Enter when Ganache is running on port 8545..."
fi

# 2. Start Asterisk
echo -e "\n${BLUE}📞 Step 2: Starting Asterisk...${NC}"
if systemctl is-active --quiet asterisk; then
    echo -e "${GREEN}✅ Asterisk is already running${NC}"
else
    echo "Starting Asterisk (may require sudo)..."
    sudo systemctl start asterisk || {
        echo -e "${YELLOW}⚠️  Failed to start Asterisk via systemctl. Trying direct start...${NC}"
        sudo asterisk -c &
    }
    sleep 5
    
    if systemctl is-active --quiet asterisk; then
        echo -e "${GREEN}✅ Asterisk started successfully${NC}"
    else
        echo -e "${YELLOW}⚠️  Asterisk may not be running. Please check manually${NC}"
    fi
fi

# 3. Initialize and start IPFS
echo -e "\n${BLUE}🌐 Step 3: Starting IPFS...${NC}"
if ! ipfs id &>/dev/null; then
    echo "Initializing IPFS..."
    ipfs init
fi

# Check if IPFS is already running
if ! nc -z localhost 5001 2>/dev/null; then
    echo "Starting IPFS daemon..."
    ipfs daemon &
    IPFS_PID=$!
    check_service "IPFS API" 5001
    check_service "IPFS Gateway" 8080
else
    echo -e "${GREEN}✅ IPFS is already running${NC}"
fi

# 4. Navigate to Blockchain directory
echo -e "\n${BLUE}📁 Step 4: Setting up Blockchain environment...${NC}"
BLOCKCHAIN_DIR="Voip_security-main/Blockchain"
if [ -d "$BLOCKCHAIN_DIR" ]; then
    cd "$BLOCKCHAIN_DIR"
    echo "Working directory: $(pwd)"
else
    echo -e "${RED}❌ Blockchain directory not found: $BLOCKCHAIN_DIR${NC}"
    echo "Please run this script from the correct directory"
    exit 1
fi

# 5. Setup Python environment and install dependencies
echo -e "\n${BLUE}🐍 Step 5: Setting up Python environment...${NC}"

# Check if we're in an externally managed environment (like Kali Linux)
# Try a test pip install to detect externally managed environment
if python3 -m pip install --dry-run --quiet pip 2>&1 | grep -q "externally-managed-environment" || [ -f "/etc/kali-release" ]; then
    echo "Detected externally managed Python environment (Kali Linux)"

    # Create virtual environment if it doesn't exist
    if [ ! -d "venv" ]; then
        echo "Creating Python virtual environment..."
        python3 -m venv venv
    fi

    # Activate virtual environment
    echo "Activating virtual environment..."
    source venv/bin/activate

    # Upgrade pip in virtual environment
    pip install --upgrade pip

    # Install dependencies in virtual environment
    if [ -f "requirements.txt" ]; then
        echo "Installing dependencies from requirements.txt..."
        pip install -r requirements.txt
    else
        echo "Installing individual packages..."
        pip install fastapi uvicorn web3 requests solcx streamlit streamlit-autorefresh
    fi

    echo -e "${GREEN}✅ Virtual environment setup complete${NC}"
    VENV_ACTIVATED=true
else
    # Standard pip installation for other systems
    if [ -f "requirements.txt" ]; then
        pip3 install -r requirements.txt 2>/dev/null || {
            echo "Installing individual packages..."
            pip3 install fastapi uvicorn web3 requests solcx streamlit streamlit-autorefresh
        }
    else
        echo "Installing individual packages..."
        pip3 install fastapi uvicorn web3 requests solcx streamlit streamlit-autorefresh
    fi
    VENV_ACTIVATED=false
fi

# 6. Deploy smart contract (if needed)
echo -e "\n${BLUE}⛓️  Step 6: Deploying smart contract...${NC}"
if [ ! -f "contract_address.txt" ]; then
    echo "Deploying smart contract..."
    if [ "$VENV_ACTIVATED" = true ]; then
        python -c "
import sys
sys.path.append('.')
from Dashboard import *
print('Smart contract deployed successfully')
"
    else
        python3 -c "
import sys
sys.path.append('.')
from Dashboard import *
print('Smart contract deployed successfully')
"
    fi
else
    echo -e "${GREEN}✅ Smart contract already deployed${NC}"
fi

# 7. Start FastAPI backend
echo -e "\n${BLUE}🚀 Step 7: Starting FastAPI backend...${NC}"
if [ -f "api_server.py" ]; then
    if [ "$VENV_ACTIVATED" = true ]; then
        uvicorn api_server:app --host 0.0.0.0 --port 8000 --reload &
    else
        uvicorn api_server:app --host 0.0.0.0 --port 8000 --reload &
    fi
    FASTAPI_PID=$!
    check_service "FastAPI Backend" 8000
else
    echo -e "${YELLOW}⚠️  api_server.py not found. Skipping FastAPI backend${NC}"
fi

# 8. Start React Dashboard (if available)
echo -e "\n${BLUE}⚛️  Step 8: Starting React Dashboard...${NC}"
if [ -d "../react-dashboard" ]; then
    cd ../react-dashboard
    if [ ! -d "node_modules" ]; then
        echo "Installing React dependencies..."
        npm install
    fi
    
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

    # 8b. Start Streamlit Dashboard (fallback)
    echo -e "\n${BLUE}📊 Step 8b: Starting Streamlit Dashboard...${NC}"
    if [ "$VENV_ACTIVATED" = true ]; then
        streamlit run Dashboard.py --server.port 8501 &
    else
        streamlit run Dashboard.py --server.port 8501 &
    fi
    STREAMLIT_PID=$!
    check_service "Streamlit Dashboard" 8501
fi

# 9. Open browser windows
echo -e "\n${BLUE}🌐 Step 9: Opening browser windows...${NC}"
sleep 3

# Open dashboards
if [ ! -z "$REACT_PID" ]; then
    echo "Opening React Dashboard..."
    xdg-open "http://localhost:3000" 2>/dev/null || open "http://localhost:3000" 2>/dev/null || {
        echo "Please open http://localhost:3000 in your browser"
    }
fi

if [ ! -z "$STREAMLIT_PID" ]; then
    echo "Opening Streamlit Dashboard..."
    xdg-open "http://localhost:8501" 2>/dev/null || open "http://localhost:8501" 2>/dev/null || {
        echo "Please open http://localhost:8501 in your browser"
    }
fi

# Open FastAPI docs
if [ ! -z "$FASTAPI_PID" ]; then
    echo "Opening FastAPI Documentation..."
    xdg-open "http://localhost:8000/docs" 2>/dev/null || open "http://localhost:8000/docs" 2>/dev/null || {
        echo "Please open http://localhost:8000/docs in your browser"
    }
fi

# 10. Run OnChain.py
echo -e "\n${BLUE}⛓️  Step 10: Running OnChain.py...${NC}"
if [ -f "OnChain.py" ]; then
    if [ "$VENV_ACTIVATED" = true ]; then
        python OnChain.py
    else
        python3 OnChain.py
    fi
else
    echo -e "${YELLOW}⚠️  OnChain.py not found${NC}"
fi

# 11. System status summary
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
if [ ! -z "$STREAMLIT_PID" ]; then
    echo "• Streamlit Dashboard: http://localhost:8501"
fi
echo "• Asterisk: $(systemctl is-active asterisk 2>/dev/null || echo 'Check manually')"
echo ""
echo -e "${YELLOW}💡 Tips:${NC}"
echo "• Press Ctrl+C to stop all services"
echo "• Check $LOG_FILE for detailed logs"
echo "• All services will be cleaned up on exit"
echo ""
echo -e "${GREEN}✅ System is ready for use!${NC}"

# Keep script running and wait for user input
echo -e "\n${BLUE}🔄 System is running. Press Ctrl+C to stop all services...${NC}"
while true; do
    sleep 10
    # Optional: Add health checks here
done
