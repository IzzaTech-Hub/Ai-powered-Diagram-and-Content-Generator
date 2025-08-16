import requests
import json

# Test the class diagram variations endpoint
url = "http://127.0.0.1:5000/generate_diagram_variations"
data = {
    "userInput": "User management system with authentication",
    "diagramType": "class"
}

try:
    print("Testing class diagram variations endpoint...")
    response = requests.post(url, json=data, timeout=30)
    print(f"Status Code: {response.status_code}")
    
    if response.status_code == 200:
        result = response.json()
        print(f"Number of variations: {result.get('totalVariations', 0)}")
        print(f"Diagram type: {result.get('diagramType')}")
        
        for i, variation in enumerate(result.get('variations', [])):
            print(f"\nVariation {i+1}:")
            print(f"  Name: {variation.get('templateName')}")
            print(f"  Type: {variation.get('diagramType')}")
            print(f"  Variation: {variation.get('variation')}")
            print(f"  Color Theme: {variation.get('colorTheme')}")
            print(f"  Content length: {len(variation.get('content', ''))}")
    else:
        print(f"Error: {response.text}")
        
except Exception as e:
    print(f"Exception: {e}")

