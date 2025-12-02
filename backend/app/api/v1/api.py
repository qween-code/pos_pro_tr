"""
API Router v1 - Main API router
"""

from fastapi import APIRouter

# Import endpoint routers (to be created)
#from app.api.v1.endpoints import auth, products, orders, customers, reports

api_router = APIRouter()

# Include endpoint routers (will be added as we create them)
# api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
# api_router.include_router(products.router, prefix="/products", tags=["products"])
# api_router.include_router(orders.router, prefix="/orders", tags=["orders"])
# api_router.include_router(customers.router, prefix="/customers", tags=["customers"])
# api_router.include_router(reports.router, prefix="/reports", tags=["reports"])

# Example endpoint
@api_router.get("/ping")
async def ping():
    """Simple ping endpoint"""
    return {"message": "pong from API v1"}
