import requests
import json

# Test the newly deployed Vercel backend
url = "https://aidiagramgenerator-5sbzj7l4s-uzairhassan375s-projects.vercel.app"

print("🔍 Testing NEWLY DEPLOYED Vercel backend...")
print(f"🌐 URL: {url}")

# Test 1: Health endpoint
try:
    print("\n📡 Testing health endpoint...")
    health_response = requests.get(f"{url}/health", timeout=10)
    print(f"✅ Health Status: {health_response.status_code}")
    
    if health_response.status_code == 200:
        print("🎉 SUCCESS! Backend is working!")
        try:
            health_data = health_response.json()
            print(f"📊 Server status: {health_data.get('status', 'N/A')}")
            print(f"🤖 AI service: {health_data.get('groq_client', 'N/A')}")
        except:
            print(f"📄 Response: {health_response.text[:200]}...")
    else:
        print(f"❌ Health check failed: {health_response.status_code}")
        print(f"📄 Response: {health_response.text}")
        
except Exception as e:
    print(f"💥 Health check error: {e}")

# Test 2: Variations endpoint
try:
    print("\n🎨 Testing variations endpoint...")
    variations_data = {
        "userInput": "e-commerce checkout process",
        "diagramType": "flowchart"
    }
    
    variations_response = requests.post(
        f"{url}/generate_diagram_variations",
        json=variations_data,
        timeout=30
    )
    
    print(f"✅ Variations Status: {variations_response.status_code}")
    
    if variations_response.status_code == 200:
        print("🎉 SUCCESS! Variations endpoint working!")
        try:
            result = variations_response.json()
            print(f"📊 Total variations: {result.get('totalVariations', 'N/A')}")
            
            variations = result.get('variations', [])
            print(f"🎨 Found {len(variations)} variations:")
            
            for i, variation in enumerate(variations):
                print(f"  - Variation {i+1}: {variation.get('templateName', 'N/A')}")
                
        except Exception as e:
            print(f"📄 Response parsing error: {e}")
            print(f"📄 Raw response: {variations_response.text[:300]}...")
    else:
        print(f"❌ Variations endpoint failed: {variations_response.status_code}")
        print(f"📄 Response: {variations_response.text}")
        
except Exception as e:
    print(f"💥 Variations test error: {e}")

print("\n�� Test completed!")
