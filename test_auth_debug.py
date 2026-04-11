#!/usr/bin/env python3
"""
Debug script para testar autenticação e validar token JWT
"""
import urllib.request
import urllib.parse
import json

BASE_URL = "http://127.0.0.1:8000"

def test_auth():
    # 1. Login
    print("1️⃣  Testing LOGIN...")
    payload = json.dumps({
        "email": "professor@test.com",
        "password": "123456"
    }).encode()
    
    req = urllib.request.Request(
        f"{BASE_URL}/api/v1/auth/login",
        data=payload,
        headers={"Content-Type": "application/json"}
    )
    
    try:
        with urllib.request.urlopen(req) as response:
            login_data = json.loads(response.read().decode())
            print(f"   Status: {response.status}")
            print(f"   Response: {json.dumps(login_data, indent=2)}")
            
            token = login_data.get("access_token")
            if not token:
                print("❌ No token in response!")
                return
                
            print(f"\n✓ Token received: {token[:50]}...")
            
            # 2. Test with Authorization header
            print("\n2️⃣  Testing with Authorization header...")
            req2 = urllib.request.Request(
                f"{BASE_URL}/api/v1/professors/exercises?limit=1",
                headers={"Authorization": f"Bearer {token}"}
            )
            
            with urllib.request.urlopen(req2) as response2:
                print(f"   Status: {response2.status}")
                data = json.loads(response2.read().decode())
                print(f"   ✓ SUCCESS! Got {len(data)} exercises")
                if data:
                    print(f"   Sample exercise keys: {list(data[0].keys())}")
    except urllib.error.HTTPError as e:
        print(f"❌ Error: {e.code} {e.reason}")
        print(f"   Response: {e.read().decode()}")

if __name__ == "__main__":
    test_auth()
