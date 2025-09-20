# 🛰 CDR Blockchain + IPFS Dashboard Setup Guide

This guide will help you set up and run the complete CDR Blockchain + IPFS system with the new React.js frontend.

## System Overview

The system consists of:
1. **Blockchain**: Ganache (local Ethereum blockchain)
2. **IPFS**: Local IPFS node for decentralized storage
3. **Backend**: FastAPI server (`api_server.py`)
4. **Frontend**: React.js dashboard (replaces Streamlit)

## Prerequisites

- **Node.js** 16+ (for React frontend)
- **Python** 3.8+ (for FastAPI backend)
- **Ganache** (for local blockchain)
- **IPFS** (for decentralized storage)

## Step-by-Step Setup

### 1. Start Ganache (Blockchain)

1. Download and install [Ganache](https://trufflesuite.com/ganache/)
2. Start Ganache with default settings:
   - Network ID: 5777
   - RPC Server: HTTP://127.0.0.1:8545
   - Accounts: 10 (with 100 ETH each)

### 2. Start IPFS Node

1. Install IPFS:
   ```bash
   # Download from https://ipfs.io/docs/install/
   # Or use the kubo binary in Blockchain/kubo/
   ```

2. Initialize and start IPFS:
   ```bash
   ipfs init
   ipfs daemon
   ```

3. Verify IPFS is running:
   - Local gateway: http://127.0.0.1:8080
   - API: http://127.0.0.1:5001

### 3. Set Up Python Backend

1. Navigate to the Blockchain directory:
   ```bash
   cd Voip_security-main/Blockchain
   ```

2. Install Python dependencies:
   ```bash
   pip install fastapi uvicorn web3 requests solcx
   ```

3. Deploy the smart contract (if not already deployed):
   ```bash
   python Dashboard.py  # This will deploy the contract and create contract_address.txt
   ```

4. Start the FastAPI backend:
   ```bash
   uvicorn api_server:app --host 0.0.0.0 --port 8000 --reload
   ```

5. Verify backend is running:
   - API docs: http://localhost:8000/docs
   - Health check: http://localhost:8000/

### 4. Set Up React Frontend

1. Navigate to the React dashboard directory:
   ```bash
   cd react-dashboard
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Create environment file:
   ```bash
   cp .env.example .env
   ```

4. Start the React development server:
   ```bash
   npm start
   ```

5. Open your browser to: http://localhost:3000

## Quick Start Scripts

### Windows
```bash
cd react-dashboard
scripts\start-dev.bat
```

### Linux/Mac
```bash
cd react-dashboard
chmod +x scripts/start-dev.sh
./scripts/start-dev.sh
```

## Verification Checklist

✅ **Ganache**: Running on port 8545  
✅ **IPFS**: Daemon running, gateway on port 8080  
✅ **Backend**: FastAPI server on port 8000  
✅ **Frontend**: React app on port 3000  
✅ **Smart Contract**: Deployed and address saved  

## Testing the System

1. **Check Dashboard**: Visit http://localhost:3000
2. **Verify Backend Health**: Green status indicator should show "Backend is running"
3. **Check CDR Data**: If you have existing CDRs, they should appear in the table
4. **Test Auto-refresh**: Dashboard updates every 5 seconds

## API Endpoints

The React frontend uses these backend endpoints:

- `GET /` - Health check
- `GET /cdrs` - Fetch all CDRs with IPFS verification
- `GET /cdr/{id}` - Fetch specific CDR
- `POST /store_cdr` - Store new CDR
- `GET /record_count` - Get total CDR count
- `GET /verify/{idx}` - Verify CDR against IPFS

## Troubleshooting

### Common Issues

1. **CORS Errors**
   - Ensure FastAPI backend has CORS middleware enabled
   - Check that React app is running on port 3000

2. **Backend Connection Failed**
   - Verify FastAPI server is running on port 8000
   - Check firewall settings
   - Ensure Ganache is running

3. **No CDR Data**
   - Check if smart contract is deployed
   - Verify contract address file exists
   - Ensure IPFS mapping file has data

4. **IPFS Links Not Working**
   - Verify IPFS daemon is running
   - Check local gateway at http://127.0.0.1:8080
   - Ensure IPFS CIDs are valid

### Debug Mode

Enable debug logging in React:
```bash
# In .env file
REACT_APP_DEBUG=true
```

Check browser console for detailed API logs.

### Backend Logs

Monitor FastAPI logs:
```bash
uvicorn api_server:app --host 0.0.0.0 --port 8000 --reload --log-level debug
```

## Production Deployment

### Backend
```bash
uvicorn api_server:app --host 0.0.0.0 --port 8000
```

### Frontend
```bash
npm run build
# Deploy build/ folder to your web server
```

## Features Comparison

| Feature | Streamlit (Old) | React.js (New) |
|---------|----------------|----------------|
| Auto-refresh | ✅ 5 seconds | ✅ 5 seconds |
| CDR Table | ✅ Basic | ✅ Sortable, searchable |
| Statistics | ✅ Basic count | ✅ Multiple metrics |
| Search | ❌ | ✅ Full-text search |
| Charts | ❌ | ✅ Interactive charts |
| QR Codes | ❌ | ✅ IPFS QR codes |
| Responsive | ❌ | ✅ Mobile-friendly |
| Error Handling | ❌ | ✅ Comprehensive |

## Next Steps

1. **Add More CDRs**: Use the original Dashboard.py to process CDR files
2. **Monitor System**: Use the React dashboard for real-time monitoring
3. **Customize**: Modify components in `src/components/` as needed
4. **Deploy**: Follow production deployment guide for live usage

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review browser console logs
3. Check backend API logs
4. Verify all services are running
