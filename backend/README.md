# 🚀 PosPro FastAPI Backend

**Enterprise-grade REST API Backend for PosPro POS System**

[![FastAPI](https://img.shields.io/badge/FastAPI-0.104+-009688?logo=fastapi)](https://fastapi.tiangolo.com)
[![Python](https://img.shields.io/badge/Python-3.11+-3776AB?logo=python)](https://python.org)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15+-4169E1?logo=postgresql)](https://postgresql.org)
[![Redis](https://img.shields.io/badge/Redis-7.2+-DC382D?logo=redis)](https://redis.io)
[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?logo=docker)](https://docker.com)

---

## 🎯 Features

### Core Features
- ✅ **High Performance** - Async/await, ASGI server (Uvicorn)
- ✅ **Auto Documentation** - Swagger UI & ReDoc
- ✅ **Type Safety** - Pydantic models with validation
- ✅ **Security** - JWT authentication, OAuth2, rate limiting
- ✅ **Database** - PostgreSQL with async SQLAlchemy 2.0
- ✅ **Caching** - Redis for performance
- ✅ **Testing** - Pytest with 90%+ coverage
- ✅ **Docker** - Production-ready containerization

### Production Features
- 🔐 **Security**: JWT + OAuth2 + Rate Limiting + CORS
- 📊 **Monitoring**: Health checks, metrics, logging
- 🚀 **Performance**: Redis caching, database pooling
- 🔄 **Scalability**: Horizontal scaling, load balancing
- 📝 **Documentation**: Auto-generated API docs
- 🧪 **Testing**: Unit + integration tests
- 🐳 **DevOps**: Docker + Docker Compose

---

## 🏗️ Architecture

```
backend/
├── app/
│   ├── api/                      # API Routes
│   │   ├── v1/                   # API Version 1
│   │   │   ├── endpoints/
│   │   │   │   ├── auth.py       # Authentication
│   │   │   │   ├── products.py   # Product CRUD
│   │   │   │   ├── orders.py     # Order management
│   │   │   │   ├── customers.py  # Customer management
│   │   │   │   ├── reports.py    # Analytics & reports
│   │   │   │   └── health.py     # Health checks
│   │   │   └── api.py            # API router
│   │   └── deps.py               # Dependencies
│   │
│   ├── core/                     # Core Configuration
│   │   ├── config.py             # Settings (Pydantic)
│   │   ├── security.py           # JWT, OAuth2, hashing
│   │   └── logging.py            # Structured logging
│   │
│   ├── db/                       # Database
│   │   ├── base.py               # SQLAlchemy base
│   │   ├── session.py            # DB sessions
│   │   └── init_db.py            # DB initialization
│   │
│   ├── models/                   # SQLAlchemy Models
│   │   ├── user.py
│   │   ├── product.py
│   │   ├── order.py
│   │   ├── customer.py
│   │   └── ...
│   │
│   ├── schemas/                  # Pydantic Schemas
│   │   ├── user.py
│   │   ├── product.py
│   │   ├── order.py
│   │   └── ...
│   │
│   ├── services/                 # Business Logic
│   │   ├── product_service.py
│   │   ├── order_service.py
│   │   ├── auth_service.py
│   │   └── cache_service.py
│   │
│   ├── middleware/               # Middleware
│   │   ├── rate_limit.py
│   │   ├── cors.py
│   │   └── logging.py
│   │
│   └── main.py                   # FastAPI app
│
├── tests/                        # Tests
│   ├── unit/
│   ├── integration/
│   └── conftest.py
│
├── alembic/                      # Database Migrations
│   ├── versions/
│   └── env.py
│
├── docker/                       # Docker configs
│   ├── Dockerfile
│   ├── Dockerfile.prod
│   └── nginx.conf
│
├── scripts/                      # Utility scripts
│   ├── seed_db.py
│   └── generate_docs.py
│
├── .env.example                  # Environment template
├── docker-compose.yml            # Development setup
├── docker-compose.prod.yml       # Production setup
├── pyproject.toml                # Poetry dependencies
├── requirements.txt              # Pip dependencies
└── README.md                     # This file
```

---

## 🚀 Quick Start

### Prerequisites
- Python 3.11+
- Docker & Docker Compose
- PostgreSQL 15+
- Redis 7+

### Option 1: Docker (Recommended) 🐳

**One-click setup:**

```bash
# Start all services
docker-compose up -d

# API: http://localhost:8000
# Docs: http://localhost:8000/docs
# ReDoc: http://localhost:8000/redoc
```

That's it! 🎉

### Option 2: Local Development

```bash
# 1. Create virtual environment
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# 2. Install dependencies
pip install -r requirements.txt

# 3. Setup environment
cp .env.example .env
# Edit .env with your database credentials

# 4. Run migrations
alembic upgrade head

# 5. Seed database (optional)
python scripts/seed_db.py

# 6. Start server
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

---

## 📡 API Endpoints

### Base URL
- **Local**: `http://localhost:8000`
- **Staging**: `https://api-staging.pospro.com`
- **Production**: `https://api.pospro.com`

### Authentication
```http
POST   /api/v1/auth/register     # Register new user
POST   /api/v1/auth/login        # Login (get JWT token)
POST   /api/v1/auth/refresh      # Refresh token
GET    /api/v1/auth/me           # Get current user
```

### Products
```http
GET    /api/v1/products          # List products (paginated)
GET    /api/v1/products/{id}     # Get product
POST   /api/v1/products          # Create product
PUT    /api/v1/products/{id}     # Update product
DELETE /api/v1/products/{id}     # Delete product
PATCH  /api/v1/products/{id}/stock  # Update stock
GET    /api/v1/products/low-stock    # Low stock alerts
```

### Orders
```http
GET    /api/v1/orders            # List orders (paginated)
GET    /api/v1/orders/{id}       # Get order details
POST   /api/v1/orders            # Create order
PUT    /api/v1/orders/{id}       # Update order
POST   /api/v1/orders/{id}/refund    # Refund order
GET    /api/v1/orders/stats      # Order statistics
```

### Customers
```http
GET    /api/v1/customers         # List customers
GET    /api/v1/customers/{id}    # Get customer
POST   /api/v1/customers         # Create customer
PUT    /api/v1/customers/{id}    # Update customer
GET    /api/v1/customers/{id}/orders  # Customer orders
```

### Reports
```http
GET    /api/v1/reports/daily     # Daily sales report
GET    /api/v1/reports/weekly    # Weekly analytics
GET    /api/v1/reports/monthly   # Monthly summary
GET    /api/v1/reports/products  # Product analytics
GET    /api/v1/reports/cashiers  # Cashier performance
```

### Health & Monitoring
```http
GET    /health                   # Health check
GET    /metrics                  # Prometheus metrics
GET    /api/v1/ping              # Simple ping
```

---

## 🔐 Authentication

### JWT Token Flow

```python
# 1. Login
POST /api/v1/auth/login
{
  "email": "admin@pospro.com",
  "password": "secure123"
}

# Response:
{
  "access_token": "eyJhbGc...",
  "token_type": "bearer",
  "expires_in": 3600
}

# 2. Use token in subsequent requests
Authorization: Bearer eyJhbGc...
```

### Security Features
- ✅ JWT tokens (1 hour expiry)
- ✅ Refresh tokens (7 days)
- ✅ Password hashing (bcrypt)
- ✅ Role-based access control (RBAC)
- ✅ Rate limiting (100 req/min)
- ✅ CORS protection
- ✅ SQL injection prevention
- ✅ XSS protection

---

## 📊 Database Schema

### Key Tables
- `users` - User accounts
- `products` - Product catalog
- `orders` - Sales orders
- `order_items` - Order line items
- `customers` - Customer records
- `payments` - Payment transactions
- `registers` - Cash register sessions
- `branches` - Store branches

### Migrations

```bash
# Create new migration
alembic revision --autogenerate -m "Add new table"

# Apply migrations
alembic upgrade head

# Rollback one version
alembic downgrade -1

# See migration history
alembic history
```

---

## 🧪 Testing

```bash
# Run all tests
pytest

# With coverage
pytest --cov=app --cov-report=html

# Specific test
pytest tests/unit/test_products.py

# Integration tests only
pytest tests/integration/
```

### Test Coverage Goals
- ✅ Unit tests: 90%+
- ✅ Integration tests: 80%+
- ✅ E2E tests: Critical paths

---

## 🚀 Deployment

### Docker Production

```bash
# Build production image
docker build -f docker/Dockerfile.prod -t pospro-api:latest .

# Run with docker-compose
docker-compose -f docker-compose.prod.yml up -d

# Scale workers
docker-compose -f docker-compose.prod.yml up -d --scale api=3
```

### Environment Variables

```bash
# Required
DATABASE_URL=postgresql://user:pass@localhost/pospro
SECRET_KEY=your-secret-key-here
REDIS_URL=redis://localhost:6379

# Optional
DEBUG=false
LOG_LEVEL=INFO
CORS_ORIGINS=["https://pospro.com"]
MAX_CONNECTIONS=100
```

### Performance Tuning

```python
# Uvicorn workers (CPU cores * 2 + 1)
uvicorn app.main:app --workers 4 --worker-class uvicorn.workers.UvicornWorker

# With Gunicorn
gunicorn app.main:app -w 4 -k uvicorn.workers.UvicornWorker
```

---

## 📈 Monitoring

### Health Checks

```bash
# Basic health
curl http://localhost:8000/health

# Detailed status
curl http://localhost:8000/api/v1/health/detailed
```

### Metrics (Prometheus)

```bash
# Metrics endpoint
curl http://localhost:8000/metrics
```

### Logging

```python
# Structured JSON logging
{
  "timestamp": "2025-12-02T06:49:15Z",
  "level": "INFO",
  "endpoint": "/api/v1/products",
  "method": "GET",
  "status_code": 200,
  "duration_ms": 45,
  "user_id": "123"
}
```

---

## 🔧 Configuration

### Performance Settings

```python
# config.py
DATABASE_POOL_SIZE = 20
DATABASE_MAX_OVERFLOW = 10
REDIS_CACHE_TTL = 300  # 5 minutes
RATE_LIMIT = "100/minute"
```

### Feature Flags

```python
ENABLE_CACHING = True
ENABLE_RATE_LIMITING = True
ENABLE_METRICS = True
ENABLE_CORS = True
```

---

## 📚 API Documentation

### Interactive Docs
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **OpenAPI JSON**: http://localhost:8000/openapi.json

### Example Request

```python
import requests

# Login
response = requests.post(
    "http://localhost:8000/api/v1/auth/login",
    json={"email": "admin@pospro.com", "password": "secure123"}
)
token = response.json()["access_token"]

# Get products
headers = {"Authorization": f"Bearer {token}"}
products = requests.get(
    "http://localhost:8000/api/v1/products",
    headers=headers,
    params={"limit": 20, "skip": 0}
).json()
```

---

## 🛠️ Development

### Code Quality

```bash
# Format code
black app/

# Lint
flake8 app/
pylint app/

# Type checking
mypy app/

# Security check
bandit -r app/
```

### Pre-commit Hooks

```bash
# Install hooks
pre-commit install

# Run manually
pre-commit run --all-files
```

---

## 🎓 Learning Resources

- [FastAPI Documentation](https://fastapi.tiangolo.com)
- [Pydantic Documentation](https://docs.pydantic.dev)
- [SQLAlchemy 2.0](https://docs.sqlalchemy.org)
- [Alembic](https://alembic.sqlalchemy.org)

---

## 💡 Tips & Best Practices

### Performance
```python
# ✅ Use async/await
async def get_products():
    return await db.query(Product).all()

# ✅ Use background tasks
from fastapi import BackgroundTasks
background_tasks.add_task(send_email, email)

# ✅ Cache expensive queries
@cache(expire=300)
async def get_dashboard_stats():
    ...
```

### Security
```python
# ✅ Use dependencies for auth
@app.get("/protected")
async def protected(user: User = Depends(get_current_user)):
    ...

# ✅ Validate all inputs
class ProductCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    price: float = Field(..., gt=0)
```

---

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/qween-code/pos_pro_tr/issues)
- **Discussions**: [GitHub Discussions](https://github.com/qween-code/pos_pro_tr/discussions)
- **Email**: support@pospro.com

---

## 📄 License

MIT License - see [LICENSE](../LICENSE) file

---

**Built with ❤️ using FastAPI**

[![FastAPI](https://img.shields.io/badge/Built%20with-FastAPI-009688?logo=fastapi)](https://fastapi.tiangolo.com)
