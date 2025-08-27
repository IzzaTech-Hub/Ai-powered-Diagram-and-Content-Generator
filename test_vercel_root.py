import requests

print("🔍 Testing Vercel deployment root paths...")
print("=" * 50)

base_url = "https://ai-powered-dia.vercel.app"

# Test different possible root paths
paths_to_test = [
    "/",
    "/health",
    "/api/health",
    "/status",
    "/ping",
    "/wsgi.py",
    "/app.py",
    "/backend/",
    "/backend/health",
    "/backend/wsgi.py"
]

print(f"🌐 Base URL: {base_url}")
print(f"🎯 Testing {len(paths_to_test)} different paths...")

for path in paths_to_test:
    try:
        url = f"{base_url}{path}"
        response = requests.get(url, timeout=10)
        
        if response.status_code != 404:
            print(f"🎉 SUCCESS: {path} -> Status: {response.status_code}")
            print(f"   📄 Response: {response.text[:100]}...")
            break
        else:
            print(f"❌ {path} -> 404")
            
    except Exception as e:
        print(f"💥 {path} -> Error: {str(e)[:50]}...")

print("\n" + "=" * 50)
print("🎯 Testing completed!")
print("\n💡 If all paths return 404, the issue is:")
print("   1. Root directory not set to 'backend'")
print("   2. Build configuration wrong")
print("   3. Routes not properly configured")
