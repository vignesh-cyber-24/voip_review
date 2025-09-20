#!/bin/bash

# Find Virtual Environment Script

echo "🔍 Finding Virtual Environment and Project Structure"
echo "=================================================="

echo -e "\n📁 Current directory:"
pwd

echo -e "\n📂 Contents of current directory:"
ls -la

echo -e "\n🔍 Looking for virtual environments..."
find . -name "venv" -type d 2>/dev/null | head -5

echo -e "\n🔍 Looking for Blockchain directories..."
find . -name "Blockchain" -type d 2>/dev/null | head -5

echo -e "\n🔍 Looking for React dashboard..."
find . -name "react-dashboard" -type d 2>/dev/null | head -5

echo -e "\n📋 Recommended commands:"
echo "Based on what I found, try:"

if [ -d "Voip_security-main/Blockchain/venv" ]; then
    echo "✅ Found venv in Voip_security-main/Blockchain/"
    echo "cd Voip_security-main/Blockchain && source venv/bin/activate"
elif [ -d "Voip_security-main/Voip_security-main/Blockchain/venv" ]; then
    echo "✅ Found venv in Voip_security-main/Voip_security-main/Blockchain/"
    echo "cd Voip_security-main/Voip_security-main/Blockchain && source venv/bin/activate"
else
    echo "❌ No venv found. Create one with:"
    echo "cd [Blockchain directory] && python3 -m venv venv && source venv/bin/activate"
fi
