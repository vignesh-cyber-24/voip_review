@echo off
echo 🛰 Starting CDR Blockchain + IPFS Dashboard
echo ==========================================

REM Check if Node.js is installed
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Node.js is not installed. Please install Node.js 16 or higher.
    pause
    exit /b 1
)

echo ✅ Node.js version: 
node --version

REM Check if we're in the right directory
if not exist "package.json" (
    echo ❌ package.json not found. Please run this script from the react-dashboard directory.
    pause
    exit /b 1
)

REM Install dependencies if node_modules doesn't exist
if not exist "node_modules" (
    echo 📦 Installing dependencies...
    npm install
    if %errorlevel% neq 0 (
        echo ❌ Failed to install dependencies
        pause
        exit /b 1
    )
)

REM Check if .env file exists, if not copy from example
if not exist ".env" (
    if exist ".env.example" (
        echo 📝 Creating .env file from .env.example
        copy ".env.example" ".env"
    ) else (
        echo 📝 Creating default .env file
        echo REACT_APP_API_URL=http://localhost:8000 > .env
    )
)

echo 🚀 Starting development server...
echo 📱 Dashboard will be available at: http://localhost:3000
echo 🔗 Make sure the FastAPI backend is running at: http://localhost:8000
echo.
echo Press Ctrl+C to stop the server
echo.

REM Start the development server
npm start
