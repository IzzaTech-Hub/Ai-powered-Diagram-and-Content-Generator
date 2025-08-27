import requests
import json

# Test all possible Vercel URLs
possible_urls = [
    "https://ai-powered-dia.vercel.app",
    "https://ai-powered-dia-git-main-uzairhassan375.vercel.app",
    "https://ai-powered-dia-uzairhassan375.vercel.app",
    "https://ai-powered-dia-git-main.vercel.app"
]

print("🔍 Testing all possible Vercel URLs...")

for url in possible_urls:
    print(f"\n🌐 Testing: {url}")
    
    try:
        # Test health endpoint
        health_response = requests.get(f"{url}/health", timeout=10)
        print(f"  📡 Health: {health_response.status_code}")
        
        if health_response.status_code == 200:
            print(f"  ✅ SUCCESS! Backend is working at: {url}")
            try:
                health_data = health_response.json()
                print(f"  📊 Status: {health_data.get('status', 'N/A')}")
                print(f"  🤖 AI: {health_data.get('groq_client', 'N/A')}")
            except:
                print(f"  📄 Response: {health_response.text[:100]}...")
            break
        else:
            print(f"  ❌ Health failed: {health_response.status_code}")
            print(f"  📄 Response: {health_response.text[:100]}...")
            
    except Exception as e:
        print(f"  💥 Error: {str(e)[:50]}...")

print("\n🎯 Testing completed!")
print("\n💡 If all URLs failed, check your Vercel dashboard for:")
print("   1. Build status (should be 'Ready')")
print("   2. Domain configuration")
print("   3. Environment variables (GROQ_API_KEY)")
print("   4. Python runtime settings")
