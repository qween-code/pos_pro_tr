"""
API Router v1 - Combine all endpoints
"""

from fastapi import APIRouter
from app.api.v1.endpoints import auth, pos, products

api_router = APIRouter()

# Include all endpoint routers
api_router.include_router(auth.router)
api_router.include_router(pos.router)
api_router.include_router(products.router)

# Health check
@api_router.get("/ping")
async def ping():
    """Simple ping endpoint"""
    return {"message": "pong", "status": "healthy"}
