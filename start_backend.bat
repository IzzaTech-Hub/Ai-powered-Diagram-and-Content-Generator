@echo off
echo 🚀 Starting AI Diagram Generator Backend...
echo.
echo Checking Python installation...
python --version
if %errorlevel% neq 0 (
    echo ❌ Python not found. Please install Python 3.8+ and try again.
    pause
    exit /b 1
)

echo.
echo Installing dependencies...
cd backend
pip install -r requirements.txt

echo.
echo 🌐 Starting backend server...
echo Backend will be available at: http://127.0.0.1:5000
echo Press Ctrl+C to stop the server
echo.
python app.py

pause