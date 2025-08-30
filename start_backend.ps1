flu# PowerShell script to start the Flutter App Backend Server
Write-Host "Starting Flutter App Backend Server..." -ForegroundColor Green
Write-Host ""

# Check if Python is installed
try {
    $pythonVersion = python --version
    Write-Host "Python found: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "Error: Python is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Python from https://python.org" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Navigate to backend directory
Set-Location backend

# Install Python dependencies
Write-Host "Installing Python dependencies..." -ForegroundColor Yellow
try {
    pip install -r requirements.txt
    Write-Host "Dependencies installed successfully!" -ForegroundColor Green
} catch {
    Write-Host "Error installing dependencies. Please check if pip is available." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "Setting up environment..." -ForegroundColor Yellow

# Get GROQ API key
$apiKey = Read-Host "Please enter your GROQ API key (or press Enter to skip)"

if ($apiKey) {
    $env:GROQ_API_KEY = $apiKey
    Write-Host "GROQ_API_KEY set successfully" -ForegroundColor Green
} else {
    Write-Host "No API key provided. Some AI features may not work." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Starting Flask server..." -ForegroundColor Green
Write-Host "The server will be available at: http://localhost:5000" -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host ""

# Start the Flask server
try {
    python app.py
} catch {
    Write-Host "Error starting the server: $_" -ForegroundColor Red
}

Read-Host "Press Enter to exit"

