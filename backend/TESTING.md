# 🚀 PosPro Backend - Quick Test Guide

**Testing API Endpoints Without Docker**

---

## ⚡ Quick Start (Without Docker)

### Prerequisites Check

```powershell
# Check Python version (need 3.11+)
python --version

# Check PostgreSQL (should be running)
# If not installed, use Docker for PostgreSQL only:
docker run -d -p 5432:5432 -e POSTGRES_PASSWORD=postgres123 -e POSTGRES_DB=pospro postgres:15
```

---

## 🔧 Setup Steps

### 1. Install Dependencies

```powershell
cd backend

# Create virtual environment
python -m venv venv

# Activate
.\venv\Scripts\activate

# Install requirements
pip install -r requirements.txt
```

### 2. Create Database Tables

```powershell
# Run migration script
python scripts/create_tables.py
```

### 3. Seed Demo Data

```powershell
# Add demo data
python scripts/seed_data.py
```

### 4. Start API Server

```powershell
# Run uvicorn
uvicorn app.main:app --reload --port 8000
```

---

## 🧪 Test Endpoints

### Access Swagger UI

```
Open browser: http://localhost:8000/docs
```

### Manual API Tests

#### 1. Login (Get Token)

```powershell
curl -X POST http://localhost:8000/api/v1/auth/login `
  -H "Content-Type: application/json" `
  -d '{\"email\":\"admin@pospro.com\",\"password\":\"admin123\"}'
```

**Response:**
```json
{
  "access_token": "eyJ0eXAiOiJKV1Q...",
  "refresh_token": "eyJ0eXAiOiJKV1Q...",
  "token_type": "bearer",
  "expires_in": 3600
}
```

#### 2. List Products

```powershell
# Replace YOUR_TOKEN with token from step 1
curl http://localhost:8000/api/v1/products `
  -H "Authorization: Bearer YOUR_TOKEN"
```

#### 3. Create Product

```powershell
curl -X POST http://localhost:8000/api/v1/products `
  -H "Authorization: Bearer YOUR_TOKEN" `
  -H "Content-Type: application/json" `
  -d '{
    \"name\": \"Test Product\",
    \"sku\": \"TEST001\",
    \"barcode\": \"9999999999\",
    \"base_price\": 99.90,
    \"stock_quantity\": 100
  }'
```

#### 4. Scan Barcode (POS)

```powershell
curl http://localhost:8000/api/v1/pos/scan/1234567890123 `
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## ✅ Expected Results

### Health Check
```
GET /health
Response: {"status": "healthy"}
```

### Products List
```
GET /api/v1/products
Response: {
  "total": 3,
  "skip": 0,
  "limit": 50,
  "items": [...]
}
```

### Barcode Scan
```
GET /api/v1/pos/scan/{barcode}
Response: {
  "id": "...",
  "name": "iPhone 15 Pro",
  "sku": "IPH15PRO",
  "base_price": 45999.00,
  "stock_quantity": 10
}
```

---

## 🐛 Troubleshooting

### Error: "Could not connect to database"

```powershell
# Check PostgreSQL is running
# Start PostgreSQL or use Docker:
docker run -d -p 5432:5432 -e POSTGRES_PASSWORD=postgres123 -e POSTGRES_DB=pospro postgres:15
```

### Error: "Table does not exist"

```powershell
# Run migrations
python scripts/create_tables.py
python scripts/seed_data.py
```

### Error: "No module named 'app'"

```powershell
# Make sure you're in backend/ directory
cd backend

# And venv is activated
.\venv\Scripts\activate
```

---

## 📊 Test Coverage

### Endpoints to Test:

**✅ Authentication:**
- [x] POST /api/v1/auth/login
- [x] POST /api/v1/auth/register
- [x] GET /api/v1/auth/me

**✅ POS Operations:**
- [x] GET /api/v1/pos/scan/{barcode}
- [x] POST /api/v1/pos/checkout
- [x] POST /api/v1/pos/register/open
- [x] POST /api/v1/pos/register/close

**✅ Products:**
- [x] GET /api/v1/products
- [x] POST /api/v1/products
- [x] GET /api/v1/products/{id}
- [x] PUT /api/v1/products/{id}
- [x] DELETE /api/v1/products/{id}

---

## 🚀 Next Steps After Testing

### Phase 1 Complete ✅
- [x] Products API working
- [x] POS endpoints tested
- [x] Authentication verified

### Phase 2: Orders API 🔄
```python
# Implement next:
- GET /api/v1/orders
- POST /api/v1/orders
- POST /api/v1/orders/{id}/refund
```

### Phase 3: Frontend Integration 📱
```dart
// Create API service in Flutter
class ApiService {
  Future<List<Product>> getProducts() async {
    // Call REST API
  }
}
```

---

**🎯 Once all tests pass, proceed to Orders API implementation!**
