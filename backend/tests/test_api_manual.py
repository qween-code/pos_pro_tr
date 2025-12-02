import requests
import json
import sys

BASE_URL = "http://localhost:8000/api/v1"

def print_response(response, title):
    print(f"\n{'='*20} {title} {'='*20}")
    print(f"Status: {response.status_code}")
    try:
        print(json.dumps(response.json(), indent=2))
    except:
        print(response.text)

def test_api():
    # 1. Login
    print("\n🔐 Logging in...")
    login_data = {
        "email": "admin@pospro.com",
        "password": "admin123"
    }
    response = requests.post(f"{BASE_URL}/auth/login", json=login_data)
    print_response(response, "LOGIN")
    
    if response.status_code != 200:
        print("❌ Login failed. Aborting.")
        return
        
    token = response.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    
    # 2. List Products
    print("\n📦 Listing Products...")
    response = requests.get(f"{BASE_URL}/products", headers=headers)
    print_response(response, "LIST PRODUCTS")
    
    if response.status_code != 200:
        print("❌ List products failed.")
    else:
        products = response.json().get("items", [])
        if products:
            product_id = products[0]["id"]
            print(f"✅ Found product: {product_id}")
            
            # 3. Create Order
            print("\n🛒 Creating Order...")
            order_data = {
                "branch_id": "branch-001",  # Assuming this exists from seed
                "items": [
                    {
                        "product_id": product_id,
                        "quantity": 1,
                        "unit_price": products[0]["base_price"]
                    }
                ],
                "payment_method": "cash"
            }
            # Need to find a valid branch_id first? Seed data uses generated UUIDs usually.
            # Let's check seed_data.py to see how branch_id is generated.
            # It's generated dynamically. We might need to fetch organization/branch first if endpoints exist.
            # Or just try with a dummy ID and see if it fails on FK.
            
            response = requests.post(f"{BASE_URL}/orders", json=order_data, headers=headers)
            print_response(response, "CREATE ORDER")

if __name__ == "__main__":
    try:
        test_api()
    except Exception as e:
        print(f"❌ Error: {e}")
