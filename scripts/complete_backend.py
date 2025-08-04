#!/usr/bin/env python3
"""
AI Content Generator Backend Starter Script
This script starts the Flask backend server for the AI Content Generator app.
"""

import os
import sys
import subprocess
import platform
import time

def print_banner():
    """Print a fancy banner for the script"""
    banner = """
    ╔═══════════════════════════════════════════════════════════╗
    ║                                                           ║
    ║   🚀 AI Content Generator Pro - Backend Launcher 🚀       ║
    ║                                                           ║
    ╚═══════════════════════════════════════════════════════════╝
    """
    print(banner)

def check_dependencies():
    """Check if required Python packages are installed"""
    required_packages = ['flask', 'flask-cors', 'groq']
    missing_packages = []
    
    for package in required_packages:
        try:
            __import__(package.replace('-', '_'))
            print(f"✅ {package} is installed")
        except ImportError:
            missing_packages.append(package)
            print(f"❌ {package} is not installed")
    
    if missing_packages:
        print("\n⚠️  Some required packages are missing. Installing them now...")
        try:
            subprocess.check_call([sys.executable, '-m', 'pip', 'install'] + missing_packages)
            print("✅ All required packages have been installed successfully!")
        except subprocess.CalledProcessError:
            print("❌ Failed to install required packages. Please install them manually:")
            print(f"   pip install {' '.join(missing_packages)}")
            sys.exit(1)

def find_backend_path():
    """Find the path to the backend directory"""
    # Try to find the backend directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    possible_paths = [
        os.path.join(script_dir, '..', 'backend'),  # ../backend
        os.path.join(script_dir, 'backend'),        # ./backend
        os.path.join(os.path.dirname(script_dir), 'backend')  # parent/backend
    ]
    
    for path in possible_paths:
        app_py = os.path.join(path, 'app.py')
        if os.path.isfile(app_py):
            return path
    
    print("❌ Could not find the backend directory with app.py")
    print("Please run this script from the project root or scripts directory")
    sys.exit(1)

def start_backend_server(backend_path):
    """Start the Flask backend server"""
    app_py = os.path.join(backend_path, 'app.py')
    
    print("\n🚀 Starting the AI Content Generator backend server...")
    print(f"📂 Backend path: {backend_path}")
    print("🌐 Server will be available at: http://127.0.0.1:5000")
    print("📊 Health check endpoint: http://127.0.0.1:5000/health")
    print("\n⚠️  Press Ctrl+C to stop the server\n")
    
    # Change to the backend directory and run the app
    os.chdir(backend_path)
    
    # Different command based on platform
    if platform.system() == "Windows":
        subprocess.call(['python', 'app.py'])
    else:
        subprocess.call(['python3', 'app.py'])

def main():
    """Main function to run the script"""
    print_banner()
    
    print("🔍 Checking Python dependencies...")
    check_dependencies()
    
    print("\n🔍 Finding backend directory...")
    backend_path = find_backend_path()
    
    # Start the backend server
    start_backend_server(backend_path)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n👋 Backend server stopped. Thank you for using AI Content Generator!")
        sys.exit(0) 