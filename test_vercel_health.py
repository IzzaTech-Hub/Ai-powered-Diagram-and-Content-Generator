import requests
import json

# Test Vercel backend health
url = "https://ai-powered-diagram-and-content-gene-pi.vercel.app/health"

try:
    print("🔍 Testing Vercel backend health...")
    print(f"📤 Request URL: {url}")
    
    response = requests.get(url, timeout=10)
    print(f"📥 Response Status: {response.status_code}")
    
    if response.status_code == 200:
        print("✅ Vercel backend is accessible!")
        try:
            health_data = response.json()
            print(f"📊 Server status: {health_data.get('status', 'N/A')}")
            print(f"🤖 AI service: {health_data.get('groq_client', 'N/A')}")
            print(f"⏰ Server time: {health_data.get('timestamp', 'N/A')}")
        except:
            print(f"📄 Response: {response.text[:200]}...")
    else:
        print(f"❌ Backend returned status: {response.status_code}")
        print(f"📄 Response: {response.text}")
        
except requests.exceptions.ConnectionError:
    print("❌ Connection error: Vercel backend might be down")
except Exception as e:
    print(f"💥 Exception: {e}")
