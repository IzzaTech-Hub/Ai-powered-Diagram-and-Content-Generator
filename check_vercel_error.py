import requests

print("🔍 Checking exact Vercel error response...")
print("=" * 50)

url = "https://ai-powered-dia.vercel.app"

try:
    response = requests.get(url, timeout=10)
    print(f"📡 URL: {url}")
    print(f"📊 Status: {response.status_code}")
    print(f"📏 Response size: {len(response.text)} chars")
    print(f"📄 Full response:")
    print("-" * 30)
    print(response.text)
    print("-" * 30)
    
    # Check response headers
    print(f"\n📋 Response headers:")
    for key, value in response.headers.items():
        print(f"  {key}: {value}")
        
except Exception as e:
    print(f"💥 Error: {e}")

print("\n🎯 Analysis complete!")
