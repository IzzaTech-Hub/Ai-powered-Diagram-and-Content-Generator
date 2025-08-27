import requests
import json
import time

print("🔍 COMPREHENSIVE VERCEL DEBUGGING...")
print("=" * 50)

# Test different possible Vercel URLs
vercel_urls = [
    "https://ai-powered-dia.vercel.app",
    "https://ai-powered-dia-git-main-uzairhassan375.vercel.app",
    "https://ai-powered-dia-uzairhassan375.vercel.app",
    "https://ai-powered-dia-git-main.vercel.app",
    "https://ai-powered-diagram-and-content-generator-sqiv.vercel.app"
]

print(f"🎯 Testing {len(vercel_urls)} possible Vercel URLs...")

for i, url in enumerate(vercel_urls, 1):
    print(f"\n{i}. Testing: {url}")
    
    try:
        # Test 1: Basic connectivity
        print("   📡 Testing basic connectivity...")
        response = requests.get(url, timeout=10)
        print(f"   ✅ Status: {response.status_code}")
        print(f"   📏 Response size: {len(response.text)} chars")
        
        # Test 2: Check if it's a Vercel deployment
        if "vercel" in response.text.lower():
            print("   🎯 Confirmed: This is a Vercel deployment")
        else:
            print("   ❓ Not a standard Vercel response")
            
        # Test 3: Try to find any working endpoint
        print("   🔍 Looking for any working endpoints...")
        
        # Test common endpoints
        endpoints_to_test = [
            "/",
            "/health",
            "/api/health",
            "/status",
            "/ping"
        ]
        
        for endpoint in endpoints_to_test:
            try:
                endpoint_response = requests.get(f"{url}{endpoint}", timeout=5)
                if endpoint_response.status_code != 404:
                    print(f"   🎉 Found working endpoint: {endpoint} (Status: {endpoint_response.status_code})")
                    print(f"   📄 Response: {endpoint_response.text[:100]}...")
                    break
            except:
                continue
        else:
            print("   ❌ No working endpoints found")
            
    except requests.exceptions.ConnectionError:
        print("   🔌 Connection Error: Server might be down")
    except requests.exceptions.Timeout:
        print("   ⏰ Timeout: Server is slow or unresponsive")
    except Exception as e:
        print(f"   💥 Error: {str(e)[:50]}...")

print("\n" + "=" * 50)
print("🎯 DEBUGGING COMPLETED!")
print("\n💡 RECOMMENDATIONS:")
print("1. Check Vercel dashboard for deployment status")
print("2. Verify project root directory is set to 'backend'")
print("3. Check build logs for any errors")
print("4. Ensure environment variables are set (GROQ_API_KEY)")
print("5. Try redeploying with 'Redeploy' button")
