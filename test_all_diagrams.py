import requests
import json

# Test different diagram types
diagram_types = [
    "flowchart",
    "sequence", 
    "state",
    "mind map",
    "swot analysis",
    "timeline",
    "gantt",
    "journey",
    "erd",
    "class",
    "network",
    "architecture"
]

url = "http://127.0.0.1:5000/generate_diagram_variations"

print("Testing all diagram types...")

for diagram_type in diagram_types:
    data = {
        "userInput": f"e-commerce {diagram_type} example",
        "diagramType": diagram_type
    }

    try:
        print(f"\nTesting {diagram_type}...")
        response = requests.post(url, json=data, timeout=30)
        
        if response.status_code == 200:
            result = response.json()
            variations = result.get('variations', [])
            print(f"✅ {diagram_type}: Generated {len(variations)} variations")
            
            # Check if each variation has content
            for i, variation in enumerate(variations):
                content_length = len(variation.get('content', ''))
                variation_style = variation.get('variation', 'unknown')
                print(f"   Variation {i+1} ({variation_style}): {content_length} chars")
        else:
            print(f"❌ {diagram_type}: Error {response.status_code} - {response.text}")
            
    except Exception as e:
        print(f"❌ {diagram_type}: Exception - {e}")

print("\nTest completed!")
