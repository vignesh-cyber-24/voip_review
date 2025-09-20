#!/bin/bash

# Debug script to check directory structure and virtual environment location

echo "🔍 Debugging VoIP Security System Paths"
echo "========================================"

echo -e "\n📁 Current working directory:"
pwd

echo -e "\n📂 Contents of current directory:"
ls -la

echo -e "\n🔍 Looking for Blockchain directory..."
if [ -d "Voip_security-main/Blockchain" ]; then
    echo "✅ Found: Voip_security-main/Blockchain"
    echo "Contents:"
    ls -la Voip_security-main/Blockchain/
    
    if [ -d "Voip_security-main/Blockchain/venv" ]; then
        echo "✅ Virtual environment found in Voip_security-main/Blockchain/venv"
    else
        echo "❌ No venv in Voip_security-main/Blockchain/"
    fi
fi

if [ -d "Voip_security-main/Voip_security-main/Blockchain" ]; then
    echo "✅ Found: Voip_security-main/Voip_security-main/Blockchain"
    echo "Contents:"
    ls -la Voip_security-main/Voip_security-main/Blockchain/
    
    if [ -d "Voip_security-main/Voip_security-main/Blockchain/venv" ]; then
        echo "✅ Virtual environment found in Voip_security-main/Voip_security-main/Blockchain/venv"
    else
        echo "❌ No venv in Voip_security-main/Voip_security-main/Blockchain/"
    fi
fi

if [ -d "Blockchain" ]; then
    echo "✅ Found: Blockchain"
    echo "Contents:"
    ls -la Blockchain/
    
    if [ -d "Blockchain/venv" ]; then
        echo "✅ Virtual environment found in Blockchain/venv"
    else
        echo "❌ No venv in Blockchain/"
    fi
fi

echo -e "\n🐍 Looking for virtual environments..."
find . -name "venv" -type d 2>/dev/null | head -10

echo -e "\n🔧 Python information:"
echo "Python3 location: $(which python3)"
echo "Python3 version: $(python3 --version)"

echo -e "\n📋 Recommended action:"
echo "Based on the above information, you should:"
echo "1. Navigate to the directory containing the Blockchain folder"
echo "2. Run the setup script from there"
echo "3. Or manually create the virtual environment in the correct location"
