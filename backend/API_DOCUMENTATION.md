# 🚀 PosPro FastAPI Backend - Kapsamlı API Dokümantasyonu

**World-Class REST API Architecture & Implementation Guide**

---

## 📊 API Architecture İnfografiği

### Sistem Mimarisi

```
┌─────────────────────────────────────────────────────────────────┐
│                      CLIENT APPLICATIONS                         │
│   Flutter Mobile │ React Web │ Desktop Apps │ Third-Party       │
└────────────┬────────────────────────────────────────────────────┘
             │ HTTP/HTTPS Requests
             │
             ▼
┌─────────────────────────────────────────────────────────────────┐
│                        NGINX (Load Balancer)                     │
│           SSL Termination│Rate Limiting │ Static Files          │
└────────────┬────────────────────────────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────────────────────────────┐
│                       FASTAPI APPLICATION                        │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    MIDDLEWARE STACK                       │  │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐        │  │
│  │  │    CORS    │→│Rate Limit  │→│   Logging  │         │  │
│  │  └────────────┘  └────────────┘  └────────────┘        │  │
│  └──────────────────────────┬───────────────────────────────┘  │
│                             │                                   │
│  ┌──────────────────────────▼───────────────────────────────┐  │
│  │                    API ROUTER (v1)                        │  │
│  │  /auth │ /products │ /orders │ /customers │ /reports    │  │
│  └──────────────────────────┬───────────────────────────────┘  │
│                             │                                   │
│  ┌──────────────────────────▼───────────────────────────────┐  │
│  │                  BUSINESS LOGIC LAYER                     │  │
│  │         Authentication │ Validation │ Processing           │  │
│  └──────────────────────────┬───────────────────────────────┘  │
└─────────────────────────────┼────────────────────────────────────┘
                              │
          ┌───────────────────┼───────────────────┐
          │                   │                   │
          ▼                   ▼                   ▼
    ┌──────────┐        ┌──────────┐       ┌──────────┐
    │PostgreSQL│        │  Redis   │       │ Firebase │
    │ Database │        │  Cache   │       │(Optional)│
    └──────────┘        └──────────┘       └──────────┘
```

---

## 🎯 API Endpoints (Detaylı)

### 📍 Base URL

| Environment | URL | Status |
|-------------|-----|--------|
| **Local Development** | `http://localhost:8000` | 🟢 Active |
| **Docker** | `http://localhost:8000` | 🟢 Active |
| **Staging** | `https://api-staging.pospro.com` | 🟡 Planned |
| **Production** | `https://api.pospro.com` | 🟡 Planned |

---

## 🔐 Authentication API

### Akış Diyagramı

```
┌─────────┐                          ┌─────────────┐
│ Client  │                          │   FastAPI   │
└────┬────┘                          └──────┬──────┘
     │                                      │
     │  1. POST /auth/register              │
     ├─────────────────────────────────────►│
     │  {email, password, name}             │
     │                                      │
     │  ◄─────────────────────────────────┤
     │  {user_id, email, created_at}        │
     │                                      │
     │  2. POST /auth/login                 │
     ├─────────────────────────────────────►│
     │  {email, password}                   │
     │                                      │
     │  ◄─────────────────────────────────┤
     │  {access_token, refresh_token}       │
     │                                      │
     │  3. GET /products (with token)       │
     ├─────────────────────────────────────►│
     │  Authorization: Bearer {token}       │
     │                                      │
     │  ◄─────────────────────────────────┤
     │  {products: [...]}                   │
     │                                      │
```

### Endpoints

#### 1. Register User
```http
POST /api/v1/auth/register
Content-Type: application/json

{
  "email": "cashier@pospro.com",
  "password": "SecurePass123!",
  "name": "John Doe",
  "role": "cashier"
}

Response 201:
{
  "id": "uuid-123",
  "email": "cashier@pospro.com",
  "name": "John Doe",
  "role": "cashier",
  "created_at": "2025-12-02T06:49:15Z"
}
```

#### 2. Login (Get JWT Token)
```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "email": "cashier@pospro.com",
  "password": "SecurePass123!"
}

Response 200:
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "bearer",
  "expires_in": 3600
}
```

#### 3. Refresh Token
```http
POST /api/v1/auth/refresh
Content-Type: application/json

{
  "refresh_token": "eyJhbGciOiJIUzI1NiIs..."
}

Response 200:
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "bearer",
  "expires_in": 3600
}
```

---

## 📦 Products API

### CRUD Diyagramı

```
CREATE    POST   /api/v1/products
READ      GET    /api/v1/products (list)
          GET    /api/v1/products/{id} (detail)
UPDATE    PUT    /api/v1/products/{id}
          PATCH  /api/v1/products/{id}/stock
DELETE    DELETE /api/v1/products/{id}
```

### Endpoints

#### 1. List Products (Paginated + Filtered)
```http
GET /api/v1/products?skip=0&limit=20&category=Electronics&search=phone
Authorization: Bearer {token}

Response 200:
{
  "total": 150,
  "skip": 0,
  "limit": 20,
  "items": [
    {
      "id": "prod-1",
      "name": "iPhone 15 Pro",
      "barcode": "123456789",
      "category": "Electronics",
      "price": 999.99,
      "stock": 50,
      "critical_stock_level": 10,
      "vat_rate": 0.18,
      "image_url": "https://...",
      "is_active": true,
      "created_at": "2025-12-01T10:00:00Z",
      "updated_at": "2025-12-02T06:00:00Z"
    },
    ...
  ]
}
```

#### 2. Create Product
```http
POST /api/v1/products
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "Samsung Galaxy S24",
  "barcode": "987654321",
  "category": "Electronics",
  "price": 899.99,
  "cost_price": 700.00,
  "stock": 30,
  "critical_stock_level": 5,
  "vat_rate": 0.18
}

Response 201:
{
  "id": "prod-2",
  "name": "Samsung Galaxy S24",
 ...
}
```

#### 3. Update Stock
```http
PATCH /api/v1/products/{id}/stock
Authorization: Bearer {token}
Content-Type: application/json

{
  "quantity": 100,
  "reason": "stock_purchase"
}

Response 200:
{
  "id": "prod-1",
  "old_stock": 50,
  "new_stock": 150,
  "updated_at": "2025-12-02T06:49:15Z"
}
```

#### 4. Low Stock Alert
```http
GET /api/v1/products/low-stock?threshold=10
Authorization: Bearer {token}

Response 200:
{
  "total_low_stock": 5,
  "items": [
    {
      "id": "prod-5",
      "name": "Product Name",
      "current_stock": 3,
      "critical_level": 10,
      "shortage": 7
    },
    ...
  ]
}
```

---

## 🛒 Orders API

### Order Creation Flow

```
┌──────────┐      ┌──────────────┐      ┌───────────┐
│  Client  │      │  OrderService│      │  Database │
└────┬─────┘      └──────┬───────┘      └─────┬─────┘
     │                   │                     │
     │ 1. POST /orders   │                     │
     ├──────────────────►│                     │
     │                   │                     │
     │                   │ 2. Validate Items   │
     │                   ├────────────────────►│
     │                   │ Check Stock         │
     │                   │◄────────────────────┤
     │                   │                     │
     │                   │ 3. Calculate Total  │
     │                   │    Apply Discounts  │
     │                   │                     │
     │                   │ 4. Create Order     │
     │                   ├────────────────────►│
     │                   │                     │
     │                   │ 5. Update Stock     │
     │                   ├────────────────────►│
     │                   │                     │
     │                   │ 6. Process Payment  │
     │                   ├────────────────────►│
     │                   │                     │
     │ ◄─────────────────┤◄────────────────────┤
     │ Order Created     │                     │
     │ {order_id, total} │                     │
```

### Endpoints

#### 1. Create Order
```http
POST /api/v1/orders
Authorization: Bearer {token}
Content-Type: application/json

{
  "customer_id": "cust-123",
  "cashier_id": "user-456",
  "branch_id": "branch-1",
  "items": [
    {
      "product_id": "prod-1",
      "quantity": 2,
      "unit_price": 999.99
    }
  ],
  "payments": [
    {
      "method": "cash",
      "amount": 1999.98
    }
  ],
  "discount_amount": 0,
  "notes": "Express delivery"
}

Response 201:
{
  "id": "order-789",
  "order_number": "ORD-20251202-001",
  "total_amount": 2359.98,
  "tax_amount": 359.99,
  "status": "completed",
  "created_at": "2025-12-02T06:49:15Z"
}
```

#### 2. Get Order Statistics
```http
GET /api/v1/orders/stats?start_date=2025-12-01&end_date=2025-12-02
Authorization: Bearer {token}

Response 200:
{
  "total_orders": 150,
  "total_revenue": 125000.50,
  "average_order_value": 833.34,
  "payment_methods": {
    "cash": 75000.00,
    "card": 45000.50,
    "credit": 5000.00
  },
  "top_products": [
    {"product_id": "prod-1", "quantity_sold": 50},
    ...
  ]
}
```

---

## 📈 Reports API

### Analytics Hierarchy

```
/api/v1/reports/
├── /daily         # Günlük rapor
├── /weekly        # Haftalık trend
├── /monthly       # Aylık özet
├── /products      # Ürün bazlı analitik
├── /cashiers      # Kasiyer performansı
└── /branches      # Şube karşılaştırması
```

### Weekly Sales Example

```http
GET /api/v1/reports/weekly
Authorization: Bearer {token}

Response 200:
{
  "period": {
    "start_date": "2025-11-26",
    "end_date": "2025-12-02"
  },
  "daily_sales": [
    {"date": "2025-11-26", "revenue": 12500.00, "orders": 45},
    {"date": "2025-11-27", "revenue": 15200.00, "orders": 52},
    {"date": "2025-11-28", "revenue": 18300.00, "orders": 61},
    {"date": "2025-11-29", "revenue": 14800.00, "orders": 49},
    {"date": "2025-11-30", "revenue": 16700.00, "orders": 55},
    {"date": "2025-12-01", "revenue": 19500.00, "orders": 68},
    {"date": "2025-12-02", "revenue": 21000.00, "orders": 72}
  ],
  "total_revenue": 118000.00,
  "total_orders": 402,
  "average_daily": 16857.14,
  "growth_rate": "+12.5%"
}
```

---

## ⚡ Performance & Optimization

### Caching Strategy

```
┌──────────┐
│  Client  │
└────┬─────┘
     │
     │ 1. GET /products
     ▼
┌────────────┐
│   Redis    │  ◄── Check Cache (300s TTL)
│   Cache    │
└────┬───────┘
     │ Cache HIT?
     │
     ├─ YES ──► Return Cached Data (< 5ms)
     │
     └─ NO ───► Query PostgreSQL
                └─► Store in Cache
                └─► Return Data
```

### Response Times (Benchmarks)

| Endpoint | Cached | Uncached | Target |
|----------|--------|----------|--------|
| GET /products (list) | < 10ms | < 50ms | < 100ms |
| GET /products/{id} | < 5ms | < 20ms | < 50ms |
| POST /orders | N/A | < 200ms | < 500ms |
| GET /reports/daily | < 15ms | < 100ms | < 200ms |

---

## 🔒 Security Features

### Security Layers

```
┌─────────────────────────────────────────┐
│  1. HTTPS/TLS (Encryption in Transit)   │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│  2. CORS (Cross-Origin Protection)      │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│  3. Rate Limiting (100 req/min)         │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│  4. JWT Authentication (Bearer Token)   │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│  5. RBAC (Role-Based Access Control)    │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│  6. Input Validation (Pydantic)         │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│  7. SQL Injection Prevention (ORM)      │
└─────────────────────────────────────────┘
```

---

## 🐳 Deployment Architecture

### Production Setup

```
           Load Balancer (NGINX)
                  │
      ┌───────────┼───────────┐
      │           │           │
      ▼           ▼           ▼
   API-1       API-2       API-3
   (Docker)    (Docker)    (Docker)
      │           │           │
      └───────────┴───────────┘
                  │
          ┌───────┴────────┐
          │                │
          ▼                ▼
    PostgreSQL         Redis
    (Primary)         (Cache)
          │
          ▼
    PostgreSQL
    (Replica)
```

---

## 📊 Monitoring & Metrics

### Prometheus Metrics

```http
GET /metrics

# TYPE http_requests_total counter
http_requests_total{method="GET",endpoint="/products"} 15234
http_requests_total{method="POST",endpoint="/orders"} 892

# TYPE http_request_duration_seconds histogram
http_request_duration_seconds_bucket{le="0.1"} 14500
http_request_duration_seconds_bucket{le="0.5"} 850
```

---

**Bu dokümantasyon sürekli güncellenir. En son API değişiklikleri için `/docs` endpoint'ini ziyaret edin.**

**API Versiyon:** v1.0.0  
**Son Güncelleme:** 2 Aralık 2025
