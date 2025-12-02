# PosPro Backend - Quick Start Guide

## 🚀 One-Click Startup

### Prerequisites
- Docker Desktop installed
- 5GB free disk space

### Start Everything

```bash
# From backend directory
docker-compose up -d
```

That's it! 🎉

### Access Points

- **API**: http://localhost:8000
- **API Docs (Swagger)**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **pgAdmin**: http://localhost:5050
- **Redis Commander**: http://localhost:8081

### Default Credentials

**pgAdmin:**
- Email: admin@pospro.com
- Password: admin123

**Database:**
- Host: postgres
- Port: 5432
- Database: pospro_db
- User: pospro
- Password: pospro123

## 📝 Testing API

### 1. Health Check
```bash
curl http://localhost:8000/health
```

### 2. API Documentation
Open browser: http://localhost:8000/docs

### 3. Create Test User
```bash
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@pospro.com",
    "password": "Test123!",
    "name": "Test User",
    "role": "cashier"
  }'
```

## 🛑 Stop Services

```bash
docker-compose down
```

## 🗑️ Clean Everything

```bash
docker-compose down -v
```

## 📊 View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f api
```

## 🔄 Restart Services

```bash
docker-compose restart
```

---

**Need help?** Check `/docs` endpoint or README.md
