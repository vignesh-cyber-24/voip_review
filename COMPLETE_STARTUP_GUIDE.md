# 🛰 VoIP Security System - Complete Startup Guide

This guide provides **one-command startup** for your entire VoIP CDR Blockchain + IPFS system, replacing your manual script with an automated solution.

## 🚀 Quick Start (One Command)

### Linux/Mac
```bash
chmod +x start-voip-system.sh
./start-voip-system.sh
```

### Windows
```cmd
start-voip-system.bat
```

## 📋 What the Script Does

The automated startup script handles everything in the correct order:

1. **✅ Prerequisites Check** - Verifies all required tools are installed
2. **🔗 Ganache** - Starts local blockchain on port 8545
3. **📞 Asterisk** - Starts VoIP service (with sudo if needed)
4. **🌐 IPFS** - Initializes and starts IPFS daemon
5. **⛓️ Smart Contract** - Deploys contract if not already deployed
6. **🚀 FastAPI Backend** - Starts API server on port 8000
7. **⚛️ React Dashboard** - Starts modern dashboard on port 3000
8. **📊 Streamlit** - Fallback dashboard if React not available
9. **🌐 Browser Windows** - Opens all interfaces automatically
10. **⛓️ OnChain.py** - Runs your blockchain operations

## 🔧 System Requirements

### Required Software
- **Python 3.8+** with pip
- **Node.js 16+** with npm
- **IPFS** (go-ipfs or kubo)
- **Ganache CLI** or Ganache GUI

### Optional
- **Asterisk** (for VoIP functionality)
- **Firefox/Chrome** (for automatic browser opening)

## 📦 Installation Commands

### Install Ganache CLI
```bash
npm install -g ganache-cli
```

### Install IPFS
```bash
# Linux
wget https://dist.ipfs.io/kubo/v0.24.0/kubo_v0.24.0_linux-amd64.tar.gz
tar -xzf kubo_v0.24.0_linux-amd64.tar.gz
sudo ./kubo/install.sh

# Mac
brew install ipfs

# Windows
# Download from https://dist.ipfs.io/kubo/
```

### Install Python Dependencies
```bash
cd Voip_security-main/Blockchain
pip install -r requirements.txt
```

### Install React Dependencies
```bash
cd react-dashboard
npm install
```

## 🎯 Features of the Automated Script

### ✅ Intelligent Service Management
- **Health Checks** - Verifies each service starts correctly
- **Port Monitoring** - Ensures no conflicts
- **Graceful Cleanup** - Stops all services on exit (Ctrl+C)
- **Error Handling** - Clear error messages and recovery suggestions

### 🔄 Auto-Recovery
- **Service Detection** - Skips already running services
- **Fallback Options** - Uses Streamlit if React unavailable
- **Dependency Installation** - Installs missing Python packages
- **Contract Deployment** - Deploys smart contract if needed

### 📊 Real-time Monitoring
- **Colored Output** - Easy to read status messages
- **Progress Tracking** - Shows each step completion
- **Log File** - Detailed logs in `voip_system_startup.log`
- **System Status** - Final summary of all services

## 🔍 Health Check Script

Check if everything is running properly:

```bash
chmod +x check-system.sh
./check-system.sh
```

This shows:
- ✅ Running services and ports
- 📁 Required files status
- 🔧 Installed dependencies
- 📈 Overall system health

## 🌐 Access Points After Startup

Once the script completes, you can access:

| Service | URL | Description |
|---------|-----|-------------|
| **React Dashboard** | http://localhost:3000 | Modern CDR dashboard |
| **Streamlit Dashboard** | http://localhost:8501 | Fallback dashboard |
| **FastAPI Backend** | http://localhost:8000 | REST API server |
| **API Documentation** | http://localhost:8000/docs | Interactive API docs |
| **IPFS Gateway** | http://localhost:8080 | IPFS web interface |
| **Ganache** | http://localhost:8545 | Blockchain RPC |

## 🛠️ Troubleshooting

### Common Issues

1. **Permission Denied (Asterisk)**
   ```bash
   sudo ./start-voip-system.sh
   ```

2. **Port Already in Use**
   ```bash
   # Kill existing processes
   pkill -f 'ganache|ipfs|streamlit|uvicorn'
   ./start-voip-system.sh
   ```

3. **IPFS Not Initialized**
   ```bash
   ipfs init
   ./start-voip-system.sh
   ```

4. **Missing Dependencies**
   ```bash
   # Install Node.js packages
   npm install -g ganache-cli

   # Install Python packages
   pip install -r Voip_security-main/Blockchain/requirements.txt
   ```

### Manual Service Start

If the script fails, you can start services manually:

```bash
# Terminal 1: Ganache
ganache --host 0.0.0.0 --port 8545

# Terminal 2: IPFS
ipfs daemon

# Terminal 3: FastAPI
cd Voip_security-main/Blockchain
uvicorn api_server:app --host 0.0.0.0 --port 8000

# Terminal 4: React Dashboard
cd react-dashboard
npm start
```

## 🔄 Stopping the System

The script handles cleanup automatically:

1. **Ctrl+C** in the script terminal
2. **All services stop gracefully**
3. **Browser windows remain open**

Or manually:
```bash
pkill -f 'ganache|ipfs|streamlit|uvicorn|npm'
```

## 📝 Script Customization

### Environment Variables
```bash
# Set custom ports
export GANACHE_PORT=8545
export IPFS_PORT=5001
export API_PORT=8000
export REACT_PORT=3000
```

### Configuration Files
- `react-dashboard/.env` - React environment
- `Voip_security-main/Blockchain/requirements.txt` - Python deps
- `react-dashboard/package.json` - Node.js deps

## 🎉 Success Indicators

When everything works correctly, you'll see:

```
🎉 VoIP Security System Started Successfully!
========================================
📊 System Status:
• Ganache (Blockchain): http://localhost:8545
• IPFS Gateway: http://localhost:8080
• IPFS API: http://localhost:5001
• FastAPI Backend: http://localhost:8000
• API Documentation: http://localhost:8000/docs
• React Dashboard: http://localhost:3000
• Asterisk: active

✅ System is ready for use!
```

## 🔗 Integration with Your Workflow

The script replaces your original manual process:

### Before (Manual)
```bash
sudo systemctl start asterisk
ipfs daemon &
streamlit run Dashboard.py &
firefox "http://remix.ethereum.org" &
python3 OnChain.py
```

### After (Automated)
```bash
./start-voip-system.sh
```

**Benefits:**
- ✅ **One command** starts everything
- ✅ **Error handling** and recovery
- ✅ **Health checks** ensure services work
- ✅ **Modern React dashboard** instead of Streamlit
- ✅ **Automatic browser opening**
- ✅ **Graceful shutdown** with Ctrl+C
- ✅ **Detailed logging** for debugging

## 📞 Support

If you encounter issues:

1. **Check the health script**: `./check-system.sh`
2. **Review logs**: `tail -f voip_system_startup.log`
3. **Verify prerequisites**: Ensure all required software is installed
4. **Manual verification**: Test each service individually

The automated script provides the **one-command startup** you requested while adding robust error handling and modern dashboard capabilities!
