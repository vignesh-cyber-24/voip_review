#!/bin/bash

# VoIP Security System - Health Check Script
# This script checks if all components are running properly

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 VoIP Security System Health Check${NC}"
echo "========================================"

# Function to check if a service is running on a port
check_service() {
    local service_name=$1
    local port=$2
    local url=$3
    
    if nc -z localhost $port 2>/dev/null; then
        echo -e "${GREEN}✅ $service_name${NC} - Running on port $port"
        if [ ! -z "$url" ]; then
            echo "   🌐 Access: $url"
        fi
        return 0
    else
        echo -e "${RED}❌ $service_name${NC} - Not running on port $port"
        return 1
    fi
}

# Function to check HTTP endpoint
check_http() {
    local service_name=$1
    local url=$2
    
    if curl -s "$url" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ $service_name HTTP${NC} - Responding"
        echo "   🌐 Access: $url"
        return 0
    else
        echo -e "${RED}❌ $service_name HTTP${NC} - Not responding"
        echo "   🌐 URL: $url"
        return 1
    fi
}

echo -e "\n${BLUE}📊 Checking Core Services...${NC}"

# Check Ganache (Blockchain)
check_service "Ganache (Blockchain)" 8545

# Check IPFS
check_service "IPFS API" 5001
check_service "IPFS Gateway" 8080 "http://localhost:8080"

# Check FastAPI Backend
if check_service "FastAPI Backend" 8000; then
    check_http "FastAPI" "http://localhost:8000/"
fi

# Check React Dashboard
if check_service "React Dashboard" 3000; then
    echo "   🌐 Access: http://localhost:3000"
else
    # Check Streamlit as fallback
    check_service "Streamlit Dashboard" 8501 "http://localhost:8501"
fi

echo -e "\n${BLUE}📁 Checking Files...${NC}"

# Check important files
FILES=(
    "Voip_security-main/Blockchain/contract_address.txt:Smart Contract Address"
    "Voip_security-main/Blockchain/cdr_abi.json:Contract ABI"
    "Voip_security-main/Blockchain/cdr_ipfs_map.json:IPFS Mapping"
    "react-dashboard/package.json:React Package Config"
)

for file_info in "${FILES[@]}"; do
    IFS=':' read -r file_path description <<< "$file_info"
    if [ -f "$file_path" ]; then
        echo -e "${GREEN}✅ $description${NC} - $file_path"
    else
        echo -e "${YELLOW}⚠️  $description${NC} - Missing: $file_path"
    fi
done

echo -e "\n${BLUE}🔧 Checking System Dependencies...${NC}"

# Check required commands
COMMANDS=(
    "python3:Python 3"
    "node:Node.js"
    "npm:NPM"
    "ipfs:IPFS"
    "ganache:Ganache CLI"
)

for cmd_info in "${COMMANDS[@]}"; do
    IFS=':' read -r cmd description <<< "$cmd_info"
    if command -v $cmd &> /dev/null; then
        version=$($cmd --version 2>/dev/null | head -n1 || echo "Unknown version")
        echo -e "${GREEN}✅ $description${NC} - $version"
    else
        echo -e "${YELLOW}⚠️  $description${NC} - Not installed: $cmd"
    fi
done

# Check Asterisk
echo -e "\n${BLUE}📞 Checking Asterisk...${NC}"
if systemctl is-active --quiet asterisk 2>/dev/null; then
    echo -e "${GREEN}✅ Asterisk${NC} - Running (systemctl)"
elif pgrep asterisk > /dev/null; then
    echo -e "${GREEN}✅ Asterisk${NC} - Running (process)"
else
    echo -e "${YELLOW}⚠️  Asterisk${NC} - Not running"
fi

echo -e "\n${BLUE}📈 System Summary${NC}"
echo "========================================"

# Count running services
TOTAL_SERVICES=6
RUNNING_SERVICES=0

nc -z localhost 8545 2>/dev/null && ((RUNNING_SERVICES++))
nc -z localhost 5001 2>/dev/null && ((RUNNING_SERVICES++))
nc -z localhost 8080 2>/dev/null && ((RUNNING_SERVICES++))
nc -z localhost 8000 2>/dev/null && ((RUNNING_SERVICES++))
(nc -z localhost 3000 2>/dev/null || nc -z localhost 8501 2>/dev/null) && ((RUNNING_SERVICES++))
(systemctl is-active --quiet asterisk 2>/dev/null || pgrep asterisk > /dev/null) && ((RUNNING_SERVICES++))

echo "Services Running: $RUNNING_SERVICES/$TOTAL_SERVICES"

if [ $RUNNING_SERVICES -eq $TOTAL_SERVICES ]; then
    echo -e "${GREEN}🎉 All services are running perfectly!${NC}"
elif [ $RUNNING_SERVICES -gt 3 ]; then
    echo -e "${YELLOW}⚠️  Most services are running. Check the issues above.${NC}"
else
    echo -e "${RED}❌ Several services are not running. Please start the system.${NC}"
fi

echo -e "\n${BLUE}💡 Quick Actions:${NC}"
echo "• Start all services: ./start-voip-system.sh"
echo "• View logs: tail -f voip_system_startup.log"
echo "• Stop services: pkill -f 'ganache|ipfs|streamlit|uvicorn'"

echo -e "\n${BLUE}🌐 Access URLs:${NC}"
echo "• React Dashboard: http://localhost:3000"
echo "• Streamlit Dashboard: http://localhost:8501"
echo "• FastAPI Docs: http://localhost:8000/docs"
echo "• IPFS Gateway: http://localhost:8080"
