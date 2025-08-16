import requests
import json

def test_sequence_variations():
    """Test sequence diagram variations to see structural differences"""
    
    url = "http://127.0.0.1:5000/generate_diagram_variations"
    
    test_data = {
        "userInput": "user authentication flow",
        "diagramType": "sequence"
    }
    
    try:
        print(f"Testing sequence diagram variations...")
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
                
                content = variation.get('content', '')
                
                # Count actors and interactions
                actor_count = content.count('Actor')
                message_count = content.count('message')
                interaction_count = content.count('<line')  # SVG lines for interactions
                
                print(f"Estimated interactions: {interaction_count}")
                print(f"Content length: {len(content)} characters")
                
                # Check for specific variation indicators
                if 'Logger' in content:
                    print("✓ Contains logging actor")
                if 'ErrorHandler' in content:
                    print("✓ Contains error handling")
                if 'Monitor' in content:
                    print("✓ Contains monitoring")
                if 'Validation' in content:
                    print("✓ Contains validation steps")
                
        else:
            print(f"Request failed with status {response.status_code}")
            print(f"Response: {response.text}")
            
    except Exception as e:
        print(f"Error testing sequence variations: {e}")

if __name__ == "__main__":
    test_sequence_variations()
