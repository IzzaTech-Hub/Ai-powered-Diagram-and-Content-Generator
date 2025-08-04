#!/bin/bash
echo "🚀 Starting AI Diagram Generator Backend..."
echo ""
echo "Checking Python installation..."
python3 --version
if [ $? -ne 0 ]; then
    echo "❌ Python3 not found. Please install Python 3.8+ and try again."
    exit 1
fi

echo ""
echo "Installing dependencies..."
cd backend
pip3 install -r requirements.txt

echo ""
echo "🌐 Starting backend server..."
echo "Backend will be available at: http://127.0.0.1:5000"
echo "Press Ctrl+C to stop the server"
echo ""
python3 app.py