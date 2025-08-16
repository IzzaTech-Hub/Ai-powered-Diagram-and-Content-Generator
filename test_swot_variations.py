import requests
import json
import time

def test_swot_variations():
    """Test SWOT analysis variations"""
    
    url = "http://127.0.0.1:5000/generate_diagram_variations"
    
    test_data = {
        "userInput": "new product launch",
        "diagramType": "swot analysis"
    }
    
    try:
        print(f"Testing SWOT analysis variations...")
        print(f"Input: {test_data['userInput']}")
        print(f"Type: {test_data['diagramType']}")
        
        start_time = time.time()
        response = requests.post(url, json=test_data, timeout=60)
        end_time = time.time()
        
        print(f"Response status code: {response.status_code}")
        print(f"Response time: {end_time - start_time:.2f} seconds")
        
        if response.status_code == 200:
            result = response.json()
            print(f"Total variations: {result.get('totalVariations', 0)}")
            
            for i, variation in enumerate(result.get('variations', [])):
                print(f"\n--- Variation {i+1}: {variation.get('templateName', 'Unknown')} ---")
                print(f"Style: {variation.get('variation', 'Unknown')}")
                print(f"Content length: {len(variation.get('content', ''))} characters")
                
        else:
            print(f"Request failed with status {response.status_code}")
            print(f"Response: {response.text}")
            
    except requests.exceptions.Timeout:
        print("Request timed out after 60 seconds")
    except Exception as e:
        print(f"Error testing SWOT variations: {e}")

if __name__ == "__main__":
    test_swot_variations()
