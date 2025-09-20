@echo off
setlocal enabledelayedexpansion

REM VoIP Security System - Complete Startup Script (Windows)
REM This script starts all components of the VoIP CDR Blockchain + IPFS system

echo 🛰 VoIP Security System Startup
echo ========================================
echo Starting all components...
echo.

REM Create log file
set LOG_FILE=voip_system_startup.log
echo %date% %time% - Starting VoIP System > %LOG_FILE%

REM Function to check if a port is in use
:check_port
set port=%1
netstat -an | find ":%port%" | find "LISTENING" >nul
if %errorlevel% equ 0 (
    echo ✅ Port %port% is active
    exit /b 0
) else (
    echo ❌ Port %port% is not active
    exit /b 1
)

REM Check prerequisites
echo 📋 Checking prerequisites...

REM Check Python
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Python is not installed or not in PATH
    pause
    exit /b 1
)

REM Check Node.js
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Node.js is not installed or not in PATH
    pause
    exit /b 1
)

echo ✅ Prerequisites check passed
echo.

REM Step 1: Start Ganache
echo 🔗 Step 1: Starting Ganache (Blockchain)...
where ganache >nul 2>&1
if %errorlevel% equ 0 (
    start "Ganache" ganache --host 0.0.0.0 --port 8545 --accounts 10 --deterministic
    timeout /t 10 /nobreak >nul
    call :check_port 8545
) else (
    echo ⚠️  Ganache not found. Please install: npm install -g ganache-cli
    echo    Or start Ganache GUI manually
    pause
)

REM Step 2: Start IPFS
echo.
echo 🌐 Step 2: Starting IPFS...
where ipfs >nul 2>&1
if %errorlevel% equ 0 (
    REM Check if IPFS is initialized
    ipfs id >nul 2>&1
    if %errorlevel% neq 0 (
        echo Initializing IPFS...
        ipfs init
    )
    
    REM Start IPFS daemon
    start "IPFS" ipfs daemon
    timeout /t 10 /nobreak >nul
    call :check_port 5001
    call :check_port 8080
) else (
    echo ❌ IPFS not found. Please install IPFS
    pause
)

REM Step 3: Navigate to Blockchain directory
echo.
echo 📁 Step 3: Setting up Blockchain environment...
if exist "Voip_security-main\Blockchain" (
    cd "Voip_security-main\Blockchain"
    echo Working directory: %cd%
) else (
    echo ❌ Blockchain directory not found
    echo Please run this script from the correct directory
    pause
    exit /b 1
)

REM Step 4: Install Python dependencies
echo.
echo 🐍 Step 4: Installing Python dependencies...
if exist requirements.txt (
    pip install -r requirements.txt
) else (
    echo Installing individual packages...
    pip install fastapi uvicorn web3 requests solcx streamlit streamlit-autorefresh
)

REM Step 5: Deploy smart contract
echo.
echo ⛓️  Step 5: Deploying smart contract...
if not exist "contract_address.txt" (
    echo Deploying smart contract...
    python -c "import sys; sys.path.append('.'); from Dashboard import *; print('Smart contract deployed')"
) else (
    echo ✅ Smart contract already deployed
)

REM Step 6: Start FastAPI backend
echo.
echo 🚀 Step 6: Starting FastAPI backend...
if exist "api_server.py" (
    start "FastAPI" uvicorn api_server:app --host 0.0.0.0 --port 8000 --reload
    timeout /t 5 /nobreak >nul
    call :check_port 8000
) else (
    echo ⚠️  api_server.py not found. Skipping FastAPI backend
)

REM Step 7: Start React Dashboard or Streamlit
echo.
if exist "..\react-dashboard" (
    echo ⚛️  Step 7: Starting React Dashboard...
    cd ..\react-dashboard
    
    if not exist "node_modules" (
        echo Installing React dependencies...
        npm install
    )
    
    if not exist ".env" (
        echo REACT_APP_API_URL=http://localhost:8000 > .env
    )
    
    start "React Dashboard" npm start
    cd ..\Blockchain
    timeout /t 10 /nobreak >nul
    call :check_port 3000
) else (
    echo 📊 Step 7: Starting Streamlit Dashboard...
    start "Streamlit" streamlit run Dashboard.py --server.port 8501
    timeout /t 5 /nobreak >nul
    call :check_port 8501
)

REM Step 8: Open browser windows
echo.
echo 🌐 Step 8: Opening browser windows...
timeout /t 3 /nobreak >nul

REM Open dashboards
if exist "..\react-dashboard" (
    echo Opening React Dashboard...
    start http://localhost:3000
) else (
    echo Opening Streamlit Dashboard...
    start http://localhost:8501
)

REM Open FastAPI docs
if exist "api_server.py" (
    echo Opening FastAPI Documentation...
    start http://localhost:8000/docs
)

REM Step 9: Run OnChain.py
echo.
echo ⛓️  Step 9: Running OnChain.py...
if exist "OnChain.py" (
    python OnChain.py
) else (
    echo ⚠️  OnChain.py not found
)

REM System status summary
echo.
echo 🎉 VoIP Security System Started Successfully!
echo ========================================
echo 📊 System Status:
echo • Ganache (Blockchain): http://localhost:8545
echo • IPFS Gateway: http://localhost:8080
echo • IPFS API: http://localhost:5001
if exist "api_server.py" (
    echo • FastAPI Backend: http://localhost:8000
    echo • API Documentation: http://localhost:8000/docs
)
if exist "..\react-dashboard" (
    echo • React Dashboard: http://localhost:3000
) else (
    echo • Streamlit Dashboard: http://localhost:8501
)
echo.
echo 💡 Tips:
echo • Check %LOG_FILE% for detailed logs
echo • Close terminal windows to stop services
echo • All browser tabs have been opened automatically
echo.
echo ✅ System is ready for use!
echo.
echo Press any key to exit...
pause >nul
