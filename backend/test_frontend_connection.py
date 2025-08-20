#!/usr/bin/env python3
"""
Test script to diagnose frontend connection issues
"""
import requests
import json
import time

def test_endpoints():
    """Test all the endpoints that the Flutter app uses"""
    
    base_urls = [
        'http://127.0.0.1:5000',
        'https://diagramgenerator-hj9d.onrender.com'
    ]
    
    test_cases = [
        {
            'name': 'Health Check',
            'method': 'GET',
            'endpoint': '/health',
            'data': None
        },
        {
            'name': 'Generate Napkin Diagram',
            'method': 'POST',
            'endpoint': '/generate_napkin_diagram',
            'data': {
                'userInput': 'Create a simple flowchart for user registration',
                'napkinTemplate': {
                    'name': 'User Registration Flowchart',
                    'napkinType': 'flowchart'
                }
            }
        },
        {
            'name': 'Generate Document',
            'method': 'POST',
            'endpoint': '/generate_document',
            'data': {
                'userInput': 'Create a business plan for an e-commerce website',
                'documentTemplate': {
                    'name': 'Business Plan',
                    'documentType': 'business',
                    'promptInstruction': 'Create a detailed business plan for [USER_INPUT].'
                }
            }
        },
        {
            'name': 'Regenerate Diagram',
            'method': 'POST',
            'endpoint': '/regenerate_diagram',
            'data': {
                'prompt': 'Make it more detailed',
                'diagramType': 'flowchart',
                'currentSvg': '<svg>test</svg>'
            }
        }
    ]
    
    for base_url in base_urls:
        print(f"\n{'='*60}")
        print(f"Testing backend: {base_url}")
        print(f"{'='*60}")
        
        for test_case in test_cases:
            print(f"\n🔍 Testing: {test_case['name']}")
            print(f"   Endpoint: {test_case['endpoint']}")
            
            try:
                url = f"{base_url}{test_case['endpoint']}"
                headers = {'Content-Type': 'application/json'}
                
                if test_case['method'] == 'GET':
                    response = requests.get(url, timeout=10)
                else:
                    response = requests.post(
                        url, 
                        headers=headers,
                        json=test_case['data'],
                        timeout=30
                    )
                
                print(f"   ✅ Status: {response.status_code}")
                print(f"   📏 Response size: {len(response.text)} chars")
                
                # Show first 200 chars of response for debugging
                if response.status_code == 200:
                    content_preview = response.text[:200].replace('\n', ' ')
                    print(f"   📄 Preview: {content_preview}...")
                    
                    # Special handling for specific endpoints
                    if test_case['endpoint'] == '/health':
                        health_data = response.json()
                        print(f"   🔧 Groq client: {health_data.get('groq_client', 'unknown')}")
                        print(f"   📅 Timestamp: {health_data.get('timestamp', 'unknown')}")
                        
                else:
                    print(f"   ❌ Error: {response.text[:200]}")
                    
            except requests.exceptions.ConnectionError:
                print(f"   🔴 Connection failed - server not reachable")
            except requests.exceptions.Timeout:
                print(f"   ⏰ Request timed out")
            except Exception as e:
                print(f"   💥 Error: {str(e)}")
    
    print(f"\n{'='*60}")
    print("DIAGNOSIS COMPLETE")
    print(f"{'='*60}")
    print("\n📱 For Flutter app debugging:")
    print("1. Check if your app is connecting to the right URL")
    print("2. Verify CORS headers are being handled correctly")
    print("3. Check network permissions in your Flutter app")
    print("4. Test with Android emulator and real device separately")
    print("\n🔧 Next steps:")
    print("1. If local server works, use: http://10.0.2.2:5000 for Android emulator")
    print("2. If local server works, use: http://192.168.X.X:5000 for real device")
    print("3. If production works, update Flutter app to prioritize production URL")

if __name__ == "__main__":
    test_endpoints()
