#!/bin/bash

# Kali Linux Setup Script for VoIP Security System
# This script sets up the environment specifically for Kali Linux

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🐧 Kali Linux Setup for VoIP Security System${NC}"
echo "=============================================="

# Check if running on Kali
if [ ! -f "/etc/kali-release" ]; then
    echo -e "${YELLOW}⚠️  This script is designed for Kali Linux${NC}"
    echo "You may need to adapt it for your distribution"
fi

echo -e "\n${BLUE}📦 Installing system packages...${NC}"

# Update package list
sudo apt update

# Install required system packages
echo "Installing Python virtual environment support..."
sudo apt install -y python3-venv python3-pip

echo "Installing Node.js and npm..."
sudo apt install -y nodejs npm

echo "Installing network tools..."
sudo apt install -y netcat-traditional curl wget

echo "Installing development tools..."
sudo apt install -y build-essential git

echo -e "\n${BLUE}🔧 Installing global Node.js packages...${NC}"

# Install Ganache CLI globally
sudo npm install -g ganache-cli

echo -e "\n${BLUE}🌐 Setting up IPFS...${NC}"

# Check if IPFS is already installed
if ! command -v ipfs &> /dev/null; then
    echo "Installing IPFS (Kubo)..."
    
    # Download and install IPFS
    IPFS_VERSION="v0.30.0"
    IPFS_ARCH="linux-amd64"
    
    cd /tmp
    wget "https://dist.ipfs.io/kubo/${IPFS_VERSION}/kubo_${IPFS_VERSION}_${IPFS_ARCH}.tar.gz"
    tar -xzf "kubo_${IPFS_VERSION}_${IPFS_ARCH}.tar.gz"
    sudo ./kubo/install.sh
    
    # Clean up
    rm -rf kubo "kubo_${IPFS_VERSION}_${IPFS_ARCH}.tar.gz"
    
    echo -e "${GREEN}✅ IPFS installed successfully${NC}"
else
    echo -e "${GREEN}✅ IPFS is already installed${NC}"
fi

echo -e "\n${BLUE}🐍 Setting up Python virtual environment...${NC}"

# Navigate to the Blockchain directory
BLOCKCHAIN_DIR="Voip_security-main/Blockchain"
if [ -d "$BLOCKCHAIN_DIR" ]; then
    cd "$BLOCKCHAIN_DIR"
else
    echo -e "${RED}❌ Blockchain directory not found: $BLOCKCHAIN_DIR${NC}"
    echo "Please run this script from the VoIP security project root directory"
    exit 1
fi

# Create virtual environment
if [ ! -d "venv" ]; then
    echo "Creating Python virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "Activating virtual environment..."
source venv/bin/activate

# Upgrade pip
pip install --upgrade pip

# Install Python dependencies
echo "Installing Python dependencies..."
if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt
else
    pip install fastapi uvicorn web3 requests solcx streamlit streamlit-autorefresh pandas cryptography python-multipart python-dotenv
fi

echo -e "\n${BLUE}⚛️  Setting up React dashboard...${NC}"

# Navigate to React dashboard
cd ../../react-dashboard

# Install React dependencies
if [ -f "package.json" ]; then
    echo "Installing React dependencies..."
    npm install
    
    # Create .env file if it doesn't exist
    if [ ! -f ".env" ]; then
        echo "Creating .env file..."
        echo "REACT_APP_API_URL=http://localhost:8000" > .env
    fi
else
    echo -e "${YELLOW}⚠️  React dashboard not found${NC}"
fi

echo -e "\n${BLUE}🔧 Setting up Asterisk (optional)...${NC}"

# Check if Asterisk is installed
if ! command -v asterisk &> /dev/null; then
    echo "Asterisk not found. Installing..."
    sudo apt install -y asterisk
else
    echo -e "${GREEN}✅ Asterisk is already installed${NC}"
fi

echo -e "\n${BLUE}🔍 Fixing zsh history (bonus fix)...${NC}"

# Fix the zsh history corruption issue
if [ -f "$HOME/.zsh_history" ]; then
    echo "Backing up and fixing zsh history..."
    cp "$HOME/.zsh_history" "$HOME/.zsh_history.backup"
    strings "$HOME/.zsh_history.backup" > "$HOME/.zsh_history"
    echo -e "${GREEN}✅ zsh history fixed${NC}"
fi

echo -e "\n${GREEN}🎉 Kali Linux setup completed successfully!${NC}"
echo "=============================================="
echo -e "${BLUE}📋 What was installed/configured:${NC}"
echo "• Python virtual environment in Blockchain/venv"
echo "• All Python dependencies (FastAPI, Web3, Streamlit, etc.)"
echo "• Node.js and npm packages"
echo "• Ganache CLI for blockchain"
echo "• IPFS (Kubo) for decentralized storage"
echo "• React dashboard dependencies"
echo "• Asterisk VoIP server"
echo "• Fixed zsh history corruption"

echo -e "\n${BLUE}🚀 Next steps:${NC}"
echo "1. Run the startup script:"
echo "   ./start-voip-system.sh"
echo ""
echo "2. Or manually activate the Python environment:"
echo "   cd Voip_security-main/Blockchain"
echo "   source venv/bin/activate"
echo ""
echo "3. Check system health:"
echo "   ./check-system.sh"

echo -e "\n${GREEN}✅ Your Kali Linux system is now ready for the VoIP Security System!${NC}"
