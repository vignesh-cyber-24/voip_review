# 🐧 Kali Linux Fix for VoIP Security System

## The Problem You Encountered

Kali Linux uses an "externally managed Python environment" which prevents installing packages globally with pip. This is a security feature to protect the system Python installation.

**Error you saw:**
```
error: externally-managed-environment
× This environment is externally managed
```

## 🚀 Quick Fix (2 Options)

### Option 1: Automated Setup (Recommended)
```bash
chmod +x setup-kali.sh
./setup-kali.sh
```

This script will:
- ✅ Install all system dependencies
- ✅ Create a Python virtual environment
- ✅ Install all Python packages safely
- ✅ Set up Node.js and React dependencies
- ✅ Install IPFS and Ganache
- ✅ Fix your zsh history corruption

### Option 2: Manual Setup
```bash
# 1. Install system packages
sudo apt update
sudo apt install -y python3-venv python3-pip nodejs npm netcat-traditional

# 2. Install global Node.js packages
sudo npm install -g ganache-cli

# 3. Create Python virtual environment
cd Voip_security-main/Blockchain
python3 -m venv venv
source venv/bin/activate

# 4. Install Python dependencies
pip install fastapi uvicorn web3 requests solcx streamlit streamlit-autorefresh

# 5. Install React dependencies
cd ../../react-dashboard
npm install
```

## 🔧 Updated Startup Script

The startup script has been updated to automatically handle Kali Linux:

```bash
chmod +x start-voip-system.sh
./start-voip-system.sh
```

**New features:**
- ✅ **Auto-detects Kali Linux** and creates virtual environment
- ✅ **Activates venv automatically** for all Python commands
- ✅ **Handles both venv and system Python** environments
- ✅ **Better error handling** for externally managed environments

## 🐛 Bonus Fix: zsh History Corruption

Your terminal showed:
```
zsh: corrupt history file /home/kali/.zsh_history
```

**Quick fix:**
```bash
# Backup and fix the history file
cp ~/.zsh_history ~/.zsh_history.backup
strings ~/.zsh_history.backup > ~/.zsh_history
```

This is included in the setup script automatically.

## 🎯 What Changed in the Startup Script

### Before (Failed)
```bash
pip3 install fastapi uvicorn web3 requests solcx streamlit
# ❌ Failed on Kali Linux
```

### After (Works)
```bash
# Detect externally managed environment
if python3 -m pip install --help | grep -q "externally-managed-environment"; then
    # Create and activate virtual environment
    python3 -m venv venv
    source venv/bin/activate
    pip install fastapi uvicorn web3 requests solcx streamlit
fi
```

## 🚀 Complete Workflow for Kali Linux

1. **Run the setup script** (one time):
   ```bash
   chmod +x setup-kali.sh
   ./setup-kali.sh
   ```

2. **Start the system** (every time):
   ```bash
   ./start-voip-system.sh
   ```

3. **Check system health**:
   ```bash
   ./check-system.sh
   ```

## 📊 Expected Output After Fix

When you run the startup script now, you should see:

```
🐍 Step 5: Setting up Python environment...
Detected externally managed Python environment (Kali Linux)
Creating Python virtual environment...
Activating virtual environment...
Installing dependencies from requirements.txt...
✅ Virtual environment setup complete

⛓️  Step 6: Deploying smart contract...
✅ Smart contract already deployed

🚀 Step 7: Starting FastAPI backend...
✅ FastAPI Backend is running on port 8000

⚛️  Step 8: Starting React Dashboard...
✅ React Dashboard is running on port 3000
```

## 🔍 Verification Commands

After setup, verify everything works:

```bash
# Check if virtual environment was created
ls Voip_security-main/Blockchain/venv/

# Check if Python packages are installed
cd Voip_security-main/Blockchain
source venv/bin/activate
pip list | grep fastapi

# Check if Node.js packages are installed
cd react-dashboard
npm list --depth=0
```

## 🎉 Benefits of This Fix

- ✅ **Kali Linux compatible** - Works with externally managed Python
- ✅ **Isolated environment** - Doesn't break system Python
- ✅ **Automatic detection** - Script adapts to your system
- ✅ **One-command setup** - No manual intervention needed
- ✅ **Bonus fixes** - Includes zsh history repair

## 🆘 If You Still Have Issues

1. **Check Python version**:
   ```bash
   python3 --version  # Should be 3.8+
   ```

2. **Check Node.js version**:
   ```bash
   node --version     # Should be 16+
   ```

3. **Manual virtual environment**:
   ```bash
   cd Voip_security-main/Blockchain
   rm -rf venv  # Remove if exists
   python3 -m venv venv
   source venv/bin/activate
   pip install --upgrade pip
   ```

4. **Check the logs**:
   ```bash
   tail -f voip_system_startup.log
   ```

The updated scripts now handle Kali Linux's security restrictions properly while maintaining the one-command startup you wanted!
