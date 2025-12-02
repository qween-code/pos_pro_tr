"""
👥 Customers API - Customer Management
CRUD Operations, Loyalty, Credit, Analytics
"""

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, func, desc, or_
from typing import List, Optional
from datetime import datetime
from decimal import Decimal

from app.db.session import get_db
from app.models.database import Customer, Order
from app.schemas.schemas import (
    CustomerCreate, CustomerUpdate, CustomerResponse, CustomerListResponse
)
from app.core.security import verify_token
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

router = APIRouter(prefix="/customers", tags=["Customers"])
security = HTTPBearer()


# ═══════════════════════════════════════════════════════════════
# LIST CUSTOMERS
# ═══════════════════════════════════════════════════════════════

@router.get("", response_model=CustomerListResponse)
async def list_customers(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    search: Optional[str] = None,  # Search by name, email, phone
    segment: Optional[str] = None,  # Filter by segment
    db: AsyncSession = Depends(get_db),
    token: HTTPAuthorizationCredentials = Depends(security)
):
    """
    📋 LIST CUSTOMERS
    
    Features:
    - Pagination
    - Search by name, email, phone
    - Filter by customer segment
    """
    payload = verify_token(token.credentials)
    org_id = payload.get("organization_id")
    
    # Build query conditions
    conditions = [Customer.organization_id == org_id]
    
    if search:
        search_pattern = f"%{search}%"
        conditions.append(
            or_(
                Customer.first_name.ilike(search_pattern),
                Customer.last_name.ilike(search_pattern),
                Customer.email.ilike(search_pattern),
                Customer.phone.ilike(search_pattern)
            )
        )
    
    if segment:
        conditions.append(Customer.segment == segment)
    
    # Count total
    count_query = select(func.count(Customer.id)).where(and_(*conditions))
    total = (await db.execute(count_query)).scalar()
    
    # Get customers
    query = (
        select(Customer)
        .where(and_(*conditions))
        .order_by(desc(Customer.created_at))
        .offset(skip)
        .limit(limit)
    )
    
    result = await db.execute(query)
    customers = result.scalars().all()
    
    return CustomerListResponse(
        total=total,
        skip=skip,
        limit=limit,
        items=customers
    )


# ═══════════════════════════════════════════════════════════════
# GET CUSTOMER
# ═══════════════════════════════════════════════════════════════

@router.get("/{customer_id}", response_model=CustomerResponse)
async def get_customer(
    customer_id: str,
    db: AsyncSession = Depends(get_db),
    token: HTTPAuthorizationCredentials = Depends(security)
):
    """🔍 GET CUSTOMER DETAILS"""
    payload = verify_token(token.credentials)
    org_id = payload.get("organization_id")
    
    query = select(Customer).where(
        and_(Customer.id == customer_id, Customer.organization_id == org_id)
    )
    result = await db.execute(query)
    customer = result.scalar_one_or_none()
    
    if not customer:
        raise HTTPException(404, "Customer not found")
    
    return customer


# ═══════════════════════════════════════════════════════════════
# CREATE CUSTOMER
# ═══════════════════════════════════════════════════════════════

@router.post("", response_model=CustomerResponse, status_code=201)
async def create_customer(
    customer_data: CustomerCreate,
    db: AsyncSession = Depends(get_db),
    token: HTTPAuthorizationCredentials = Depends(security)
):
    """
    ✨ CREATE CUSTOMER
    
    Creates a new customer record with initial tier (bronze)
    """
    payload = verify_token(token.credentials)
    org_id = payload.get("organization_id")
    
    # Check if email already exists (if provided)
    if customer_data.email:
        existing = await db.execute(
            select(Customer).where(
                and_(
                    Customer.organization_id == org_id,
                    Customer.email == customer_data.email
                )
            )
        )
        if existing.scalar_one_or_none():
            raise HTTPException(400, "Customer with this email already exists")
    
    # Create customer
    new_customer = Customer(
        organization_id=org_id,
        **customer_data.model_dump()
    )
    
    db.add(new_customer)
    await db.commit()
    await db.refresh(new_customer)
    
    return new_customer


# ═══════════════════════════════════════════════════════════════
# UPDATE CUSTOMER
# ═══════════════════════════════════════════════════════════════

@router.put("/{customer_id}", response_model=CustomerResponse)
async def update_customer(
    customer_id: str,
    customer_data: CustomerUpdate,
    db: AsyncSession = Depends(get_db),
    token: HTTPAuthorizationCredentials = Depends(security)
):
    """✏️ UPDATE CUSTOMER"""
    payload = verify_token(token.credentials)
    org_id = payload.get("organization_id")
    
    # Get customer
    query = select(Customer).where(
        and_(Customer.id == customer_id, Customer.organization_id == org_id)
    )
    result = await db.execute(query)
    customer = result.scalar_one_or_none()
    
    if not customer:
        raise HTTPException(404, "Customer not found")
    
    # Update fields
    update_data = customer_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(customer, field, value)
    
    await db.commit()
    await db.refresh(customer)
    
    return customer


# ═══════════════════════════════════════════════════════════════
# DELETE CUSTOMER
# ═══════════════════════════════════════════════════════════════

@router.delete("/{customer_id}")
async def delete_customer(
    customer_id: str,
    db: AsyncSession = Depends(get_db),
    token: HTTPAuthorizationCredentials = Depends(security)
):
    """🗑️ DELETE CUSTOMER (Soft delete)"""
    payload = verify_token(token.credentials)
    org_id = payload.get("organization_id")
    
    # Get customer
    query = select(Customer).where(
        and_(Customer.id == customer_id, Customer.organization_id == org_id)
    )
    result = await db.execute(query)
    customer = result.scalar_one_or_none()
    
    if not customer:
        raise HTTPException(404, "Customer not found")
    
    # Soft delete (mark as inactive)
    customer.is_active = False
    
    await db.commit()
    
    return {"message": "Customer deleted successfully", "id": customer_id}


# ═══════════════════════════════════════════════════════════════
# CUSTOMER ANALYTICS
# ═══════════════════════════════════════════════════════════════

@router.get("/{customer_id}/analytics")
async def customer_analytics(
    customer_id: str,
    db: AsyncSession = Depends(get_db),
    token: HTTPAuthorizationCredentials = Depends(security)
):
    """📊 CUSTOMER ANALYTICS - Purchase history and stats"""
    payload = verify_token(token.credentials)
    org_id = payload.get("organization_id")
    
    # Get customer
    customer_query = select(Customer).where(
        and_(Customer.id == customer_id, Customer.organization_id == org_id)
    )
    customer = (await db.execute(customer_query)).scalar_one_or_none()
    
    if not customer:
        raise HTTPException(404, "Customer not found")
    
    # Get order stats
    stats_query = select(
        func.count(Order.id).label("total_orders"),
        func.coalesce(func.sum(Order.total_amount), 0).label("total_spent"),
        func.avg(Order.total_amount).label("avg_order_value"),
        func.max(Order.created_at).label("last_order_date")
    ).where(
        and_(
            Order.customer_id == customer_id,
            Order.status.in_(["completed", "partial_refunded"])
        )
    )
    
    stats = (await db.execute(stats_query)).first()
    
    return {
        "customer_id": customer.id,
        "customer_name": f"{customer.first_name} {customer.last_name}",
        "email": customer.email,
        "phone": customer.phone,
        "segment": customer.segment,
        "loyalty_tier": customer.loyalty_tier,
        "loyalty_points": customer.loyalty_points,
        "total_orders": stats.total_orders,
        "total_spent": float(stats.total_spent),
        "average_order_value": float(stats.avg_order_value or 0),
        "last_order_date": stats.last_order_date.isoformat() if stats.last_order_date else None,
        "credit_limit": float(customer.credit_limit),
        "current_balance": float(customer.current_balance),
        "available_credit": float(customer.credit_limit - customer.current_balance)
    }
