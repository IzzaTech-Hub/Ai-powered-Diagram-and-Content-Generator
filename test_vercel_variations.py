import requests
import json

# Test your Vercel backend variations endpoint
url = "https://ai-powered-diagram-and-content-gene-pi.vercel.app/generate_diagram_variations"
data = {
    "userInput": "e-commerce checkout process",
    "diagramType": "flowchart"
}

try:
    print("🔍 Testing VERCEL backend variations endpoint...")
    print(f"📤 Request URL: {url}")
    print(f"📊 Request data: {json.dumps(data, indent=2)}")
    
    response = requests.post(url, json=data, timeout=60)
    print(f"📥 Response Status: {response.status_code}")
    print(f"📏 Response Headers: {dict(response.headers)}")
    
    if response.status_code == 200:
        result = response.json()
        print(f"✅ SUCCESS! Vercel backend responded!")
        print(f"📊 Total variations: {result.get('totalVariations', 'N/A')}")
        print(f"🎯 Diagram type: {result.get('diagramType', 'N/A')}")
        print(f"📝 User input: {result.get('userInput', 'N/A')}")
        
        variations = result.get('variations', [])
        print(f"\n🎨 Found {len(variations)} variations:")
        
        if len(variations) < 4:
            print(f"⚠️  WARNING: Expected 4 variations, but got {len(variations)}")
            print("🔧 This suggests the backend isn't generating all variations")
        
        for i, variation in enumerate(variations):
            print(f"\n--- Variation {i+1} ---")
            print(f"  ID: {variation.get('id', 'N/A')}")
            print(f"  Name: {variation.get('templateName', 'N/A')}")
            print(f"  Style: {variation.get('variation', 'N/A')}")
            print(f"  Color Theme: {variation.get('colorTheme', 'N/A')}")
            print(f"  Content length: {len(variation.get('content', ''))}")
            
            # Check if content is valid SVG
            content = variation.get('content', '')
            if content.startswith('<svg'):
                print(f"  ✅ Valid SVG content")
            else:
                print(f"  ❌ Invalid SVG content: {content[:100]}...")
                
    elif response.status_code == 404:
        print("❌ 404 ERROR: Variations endpoint NOT FOUND on Vercel")
        print("💡 The Vercel backend doesn't have the variations endpoint")
        
    else:
        print(f"❌ Error response: {response.status_code}")
        print(f"📄 Response: {response.text}")
        
except requests.exceptions.ConnectionError:
    print("❌ Connection error: Vercel backend might be down")
except Exception as e:
    print(f"💥 Exception: {e}")
    import traceback
    traceback.print_exc()
