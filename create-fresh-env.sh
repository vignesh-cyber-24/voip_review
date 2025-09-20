#!/bin/bash

# Create Fresh Virtual Environment for VoIP Security System

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🆕 Creating Fresh Virtual Environment${NC}"
echo "========================================"

# Navigate to the Blockchain directory
echo -e "\n${BLUE}📁 Finding Blockchain directory...${NC}"

BLOCKCHAIN_DIR=""
if [ -d "Voip_security-main/Blockchain" ]; then
    BLOCKCHAIN_DIR="Voip_security-main/Blockchain"
elif [ -d "Voip_security-main/Voip_security-main/Blockchain" ]; then
    BLOCKCHAIN_DIR="Voip_security-main/Voip_security-main/Blockchain"
elif [ -d "Blockchain" ]; then
    BLOCKCHAIN_DIR="Blockchain"
else
    echo -e "${RED}❌ Blockchain directory not found${NC}"
    echo "Current directory: $(pwd)"
    echo "Available directories:"
    ls -la
    exit 1
fi

echo -e "${GREEN}✅ Found Blockchain directory: $BLOCKCHAIN_DIR${NC}"
cd "$BLOCKCHAIN_DIR"
echo "Working in: $(pwd)"

# Remove any existing virtual environment
echo -e "\n${BLUE}🧹 Cleaning up old virtual environments...${NC}"
rm -rf venv venv_old .venv env

# Create fresh virtual environment
echo -e "\n${BLUE}🆕 Creating new virtual environment...${NC}"
python3 -m venv venv
echo -e "${GREEN}✅ Virtual environment created${NC}"

# Activate the virtual environment
echo -e "\n${BLUE}🐍 Activating virtual environment...${NC}"
source venv/bin/activate
echo -e "${GREEN}✅ Virtual environment activated${NC}"
echo "Python path: $(which python)"
echo "Python version: $(python --version)"

# Upgrade pip
echo -e "\n${BLUE}⬆️  Upgrading pip...${NC}"
pip install --upgrade pip
echo -e "${GREEN}✅ Pip upgraded to: $(pip --version)${NC}"

# Install ONLY the packages we need (NO STREAMLIT!)
echo -e "\n${BLUE}📦 Installing required packages...${NC}"
echo "Installing FastAPI and Uvicorn..."
pip install fastapi uvicorn[standard]

echo "Installing Web3 and blockchain tools..."
pip install web3 requests

echo "Installing utility packages..."
pip install python-multipart python-dotenv

# Try to install py-solc-x (optional)
echo "Installing Solidity compiler (optional)..."
pip install py-solc-x || {
    echo -e "${YELLOW}⚠️  py-solc-x failed to install (Python 3.13 compatibility issue)${NC}"
    echo "Smart contract compilation may not work, but existing contracts will work fine"
}

echo -e "${GREEN}✅ All packages installed${NC}"

# Verify installations
echo -e "\n${BLUE}🔍 Verifying installations...${NC}"
python -c "
import sys
print(f'Python: {sys.version}')

packages = ['fastapi', 'uvicorn', 'web3', 'requests']
for pkg in packages:
    try:
        module = __import__(pkg)
        version = getattr(module, '__version__', 'unknown')
        print(f'✅ {pkg}: {version}')
    except ImportError as e:
        print(f'❌ {pkg}: {e}')

# Test solcx
try:
    import solcx
    print(f'✅ solcx: {solcx.__version__}')
except ImportError:
    print('⚠️  solcx: not available (optional)')
"

# Test API server import
echo -e "\n${BLUE}🧪 Testing API server...${NC}"
if [ -f "api_server.py" ]; then
    python -c "
import sys
sys.path.append('.')
try:
    import api_server
    print('✅ API server imports successfully')
except Exception as e:
    print(f'⚠️  API server import issue: {e}')
    print('This may be due to missing contract files, but packages are installed correctly')
"
else
    echo -e "${YELLOW}⚠️  api_server.py not found in current directory${NC}"
fi

# Create a simple activation script
echo -e "\n${BLUE}📝 Creating activation script...${NC}"
cat > activate_env.sh << 'EOF'
#!/bin/bash
# Quick activation script
source venv/bin/activate
echo "✅ Virtual environment activated"
echo "Python: $(which python)"
echo "Ready to run FastAPI server!"
EOF
chmod +x activate_env.sh

echo -e "\n${GREEN}🎉 Fresh Virtual Environment Created Successfully!${NC}"
echo "========================================"
echo -e "${BLUE}📋 Summary:${NC}"
echo "• Location: $(pwd)/venv"
echo "• Python: $(python --version)"
echo "• Packages: FastAPI, Uvicorn, Web3, Requests"
echo "• Status: Ready for React-only system"

echo -e "\n${BLUE}🚀 Next Steps:${NC}"
echo "1. Stay in this terminal (venv is activated)"
echo "2. Go back to main directory:"
echo "   cd ~/Documents/Voip_security-main"
echo "3. Run the React-only startup:"
echo "   ./react-only-start.sh"
echo ""
echo "Or manually:"
echo "   uvicorn api_server:app --host 0.0.0.0 --port 8000"

echo -e "\n${BLUE}💡 To reactivate later:${NC}"
echo "cd $(pwd)"
echo "source venv/bin/activate"
echo "# or run: ./activate_env.sh"

echo -e "\n${GREEN}✅ Environment is ready! Virtual environment is currently ACTIVE.${NC}"
