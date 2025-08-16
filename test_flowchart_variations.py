import requests
import json
import time

def test_flowchart_variations():
    """Test flowchart variations to see structural differences"""
    
    url = "http://127.0.0.1:5000/generate_diagram_variations"
    
    test_data = {
        "userInput": "app development process",
        "diagramType": "flowchart"
    }
    
    try:
        print(f"Testing flowchart variations...")
        print(f"URL: {url}")
        print(f"Input: {test_data['userInput']}")
        print(f"Type: {test_data['diagramType']}")
        
        response = requests.post(url, json=test_data, timeout=30)
        print(f"Response status code: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print(f"Total variations: {result.get('totalVariations', 0)}")
            
            for i, variation in enumerate(result.get('variations', [])):
                print(f"\n--- Variation {i+1}: {variation.get('templateName', 'Unknown')} ---")
                print(f"Style: {variation.get('variation', 'Unknown')}")
                print(f"Color Theme: {variation.get('colorTheme', 'Unknown')}")
                
                # Try to extract key information from SVG content
                content = variation.get('content', '')
                if 'Step' in content:
                    step_count = content.count('Step')
                    print(f"Estimated steps: {step_count}")
                
                # Check for specific variation indicators
                if 'Validation' in content:
                    print("✓ Contains validation steps")
                if 'Pre-checks' in content:
                    print("✓ Contains pre-check steps")
                if 'Quality' in content:
                    print("✓ Contains quality gates")
                if 'Risk' in content:
                    print("✓ Contains risk assessment")
                if 'Alternative' in content:
                    print("✓ Contains alternative paths")
                
                print(f"Content length: {len(content)} characters")
                
        else:
            print(f"Request failed with status {response.status_code}")
            print(f"Response: {response.text}")
            
    except Exception as e:
        print(f"Error testing flowchart variations: {e}")

if __name__ == "__main__":
    test_flowchart_variations()
