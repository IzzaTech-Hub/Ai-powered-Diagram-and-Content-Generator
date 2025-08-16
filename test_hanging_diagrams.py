import requests
import json
import time

def test_hanging_diagrams():
    """Test specific diagrams that might be hanging"""
    
    url = "http://127.0.0.1:5000/generate_diagram_variations"
    
    test_cases = [
        {"userInput": "user login system", "diagramType": "sequence"},
        {"userInput": "online store analysis", "diagramType": "swot analysis"},
        {"userInput": "project management tool", "diagramType": "architecture"},
        {"userInput": "mobile app development", "diagramType": "timeline"}
    ]
    
    for test_case in test_cases:
        print(f"\n=== Testing {test_case['diagramType']} ===")
        print(f"Input: {test_case['userInput']}")
        
        try:
            start_time = time.time()
            response = requests.post(url, json=test_case, timeout=30)
            end_time = time.time()
            
            print(f"Response time: {end_time - start_time:.2f} seconds")
            print(f"Status code: {response.status_code}")
            
            if response.status_code == 200:
                result = response.json()
                print(f"✅ Success - Generated {result.get('totalVariations', 0)} variations")
            else:
                print(f"❌ Failed - {response.text}")
                
        except requests.exceptions.Timeout:
            print("❌ TIMEOUT - Request took longer than 30 seconds")
        except Exception as e:
            print(f"❌ ERROR - {e}")
        
        # Wait a bit between requests
        time.sleep(1)

if __name__ == "__main__":
    test_hanging_diagrams()
