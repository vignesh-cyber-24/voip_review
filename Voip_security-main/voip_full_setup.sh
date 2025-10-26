#!/bin/bash
# ===========================================
# 🚀 VOIP SECURITY PROJECT - AUTO START SCRIPT
# ===========================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}[STARTING] VoIP Blockchain Security System...${NC}"

# --- Function to check if a process is running ---
is_running() {
    pgrep -f "$1" > /dev/null 2>&1
}

# --- Hardhat project path ---
HARDHAT_PATH="/home/vignesh/Documents/VOIP_SECURITY/Voip_security/Voip_security-main/voip_contract_project"

# --- PHASE 1: Start Hardhat Node (Blockchain) ---
echo -e "${YELLOW}[1/8] Checking Hardhat node...${NC}"
if is_running "hardhat node"; then
    echo -e "${GREEN}✔ Hardhat node already running.${NC}"
else
    echo -e "${YELLOW}⚙ Starting Hardhat node on port 8545...${NC}"
    cd "$HARDHAT_PATH" || exit
    npx hardhat node > hardhat.log 2>&1 &
    sleep 5
fi

# Wait for Hardhat to respond
echo -e "${YELLOW}⏳ Waiting for Hardhat node to start...${NC}"
for i in {1..10}; do
    if nc -z 127.0.0.1 8545; then
        echo -e "${GREEN}✔ Hardhat RPC is live on port 8545.${NC}"
        break
    fi
    sleep 2
done

# --- PHASE 2: Deploy Smart Contracts (wait for completion) ---
echo -e "${YELLOW}[2/8] Deploying Hardhat contracts...${NC}"
cd "$HARDHAT_PATH" || exit
npx hardhat run scripts/deploy.ts --network localhost > deploy.log 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✔ Contracts deployed successfully.${NC}"
else
    echo -e "${RED}❌ Contract deployment failed! Check deploy.log${NC}"
    exit 1
fi

# --- PHASE 3: Start IPFS ---
echo -e "${YELLOW}[3/8] Starting IPFS daemon...${NC}"
if is_running "ipfs daemon"; then
    echo -e "${GREEN}✔ IPFS already running.${NC}"
else
    nohup ipfs daemon > ipfs.log 2>&1 &
    sleep 5
fi

# --- PHASE 4: Start Backend (FastAPI) ---
echo -e "${YELLOW}[4/8] Starting FastAPI backend...${NC}"
# Adjust the venv path if needed
cd "$HARDHAT_PATH" || exit
source venv/bin/activate
nohup uvicorn api_server:app --host 0.0.0.0 --port 8000 --reload > backend.log 2>&1 &
echo "⏳ Waiting 20 seconds for backend and blockchain to stabilize..."
sleep 20

# --- PHASE 5: Start CDR Listener ---
echo -e "${YELLOW}[5/8] Starting CDR listener...${NC}"
nohup python cdr_listener.py > cdr_listener.log 2>&1 &
sleep 3

# --- PHASE 6: Start Python Dashboard (Web3 Fetch) ---
echo -e "${YELLOW}[6/8] Starting Python dashboard to fetch contracts...${NC}"
nohup python dashboard.py > dashboard.log 2>&1 &
sleep 3

# --- PHASE 7: Start React Dashboard ---
if [ -d "../react-dashboard" ]; then
    cd ../react-dashboard || exit
elif [ -d "../../react-dashboard" ]; then
    cd ../../react-dashboard || exit
elif [ -d "../../../react-dashboard" ]; then
    cd ../../../react-dashboard || exit
else
    echo -e "${RED}❌ react-dashboard directory not found! Please check the folder path.${NC}"
    exit 1
fi

echo -e "${YELLOW}[7/8] Launching React Dashboard...${NC}"
nohup npm start > frontend.log 2>&1 &

# --- PHASE 8: Summary ---
echo ""
echo -e "${GREEN}============================================"
echo -e "✅ All systems started successfully!"
echo -e "Blockchain RPC (Hardhat): http://127.0.0.1:8545"
echo -e "Backend (FastAPI): http://localhost:8000/docs"
echo -e "Python Dashboard: Check dashboard.log for contract data"
echo -e "React Dashboard: http://localhost:3000"
echo -e "IPFS Web UI:      http://127.0.0.1:5001/webui"
echo -e "Logs:"
echo -e "  - hardhat.log"
echo -e "  - deploy.log"
echo -e "  - backend.log"
echo -e "  - cdr_listener.log"
echo -e "  - dashboard.log"
echo -e "  - frontend.log"
echo -e "============================================${NC}"
