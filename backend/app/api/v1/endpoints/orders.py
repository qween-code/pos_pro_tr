"""
📦 Orders API - Complete Order Management
Sales, Refunds, and Order Processing
"""

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, or_, func, update, desc
from sqlalchemy.orm import selectinload
from typing import List, Optional
from datetime import datetime
from decimal import Decimal

from app.db.session import get_db
from app.models.database import Order, OrderItem, Product, Customer, Payment, OrderStatusHistory
from app.schemas.schemas import (
    OrderCreate, OrderUpdate, OrderResponse, OrderListResponse,
    OrderItemCreate
)
from app.core.security import verify_token
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

router = APIRouter(prefix="/orders", tags=["Orders"])
security = HTTPBearer()


# ═══════════════════════════════════════════════════════════════
# LIST ORDERS
# ═══════════════════════════════════════════════════════════════

@router.get("", response_model=OrderListResponse)
async def list_orders(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    status: Optional[str] = None,
    customer_id: Optional[str] = None,
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    search: Optional[str] = None,  # Order ID or Customer Name
    db: AsyncSession = Depends(get_db),
    token: HTTPAuthorizationCredentials = Depends(security)
):
    """
    📋 LIST ORDERS
    
    Features:
    - Pagination
    - Filter by status, customer, date range
    - Search by Order ID
    """
    payload = verify_token(token.credentials)
    org_id = payload.get("organization_id")
    
    # Build query
    conditions = [Order.organization_id == org_id]
    
    if status:
        conditions.append(Order.status == status)
    if customer_id:
        conditions.append(Order.customer_id == customer_id)
    if start_date:
        conditions.append(Order.created_at >= start_date)
    if end_date:
        conditions.append(Order.created_at <= end_date)
    if search:
        conditions.append(Order.id.ilike(f"%{search}%"))

    # Count total
    count_query = select(func.count(Order.id)).where(and_(*conditions))
    total = (await db.execute(count_query)).scalar()
    
    # Get orders with relations
    query = (
        select(Order)
        .options(selectinload(Order.items), selectinload(Order.customer))
        .where(and_(*conditions))
        .order_by(desc(Order.created_at))
        .offset(skip)
        .limit(limit)
    )
    
    result = await db.execute(query)
    orders = result.scalars().all()
    
    return OrderListResponse(
        total=total,
        skip=skip,
        limit=limit,
        items=orders
    )


# ═══════════════════════════════════════════════════════════════
# GET ORDER
# ═══════════════════════════════════════════════════════════════

@router.get("/{order_id}", response_model=OrderResponse)
async def get_order(
    order_id: str,
    db: AsyncSession = Depends(get_db),
    token: HTTPAuthorizationCredentials = Depends(security)
):
    """🔍 GET ORDER DETAILS"""
    payload = verify_token(token.credentials)
    org_id = payload.get("organization_id")
    
    query = (
        select(Order)
        .options(
            selectinload(Order.items).selectinload(OrderItem.product),
            selectinload(Order.customer),
            selectinload(Order.payments)
        )
        .where(and_(Order.id == order_id, Order.organization_id == org_id))
    )
    result = await db.execute(query)
    order = result.scalar_one_or_none()
    
    if not order:
        raise HTTPException(404, "Order not found")
    
    return order


# ═══════════════════════════════════════════════════════════════
# CREATE ORDER
# ═══════════════════════════════════════════════════════════════

@router.post("", response_model=OrderResponse, status_code=201)
async def create_order(
    order_data: OrderCreate,
    db: AsyncSession = Depends(get_db),
    token: HTTPAuthorizationCredentials = Depends(security)
):
    """
    🛒 CREATE ORDER
    
    - Creates order and order items
    - Updates product stock
    - Records initial payment (if provided)
    """
    payload = verify_token(token.credentials)
    org_id = payload.get("organization_id")
    user_id = payload.get("sub")
    
    # 1. Validate Products & Stock
    total_amount = Decimal("0.00")
    items_to_create = []
    
    for item in order_data.items:
        # Get product
        result = await db.execute(
            select(Product).where(
                and_(Product.id == item.product_id, Product.organization_id == org_id)
            )
        )
        product = result.scalar_one_or_none()
        
        if not product:
            raise HTTPException(400, f"Product {item.product_id} not found")
        
        if not product.is_active:
            raise HTTPException(400, f"Product {product.name} is not active")
            
        if product.track_inventory and product.stock_quantity < item.quantity:
            raise HTTPException(400, f"Insufficient stock for {product.name}. Available: {product.stock_quantity}")
            
        # Calculate totals
        unit_price = product.sale_price or product.base_price
        total_price = unit_price * item.quantity
        total_amount += total_price
        
        # Prepare item
        items_to_create.append({
            "product": product,
            "quantity": item.quantity,
            "unit_price": unit_price,
            "total_price": total_price
        })

    # 2. Create Order
    new_order = Order(
        organization_id=org_id,
        branch_id=order_data.branch_id,
        customer_id=order_data.customer_id,
        cashier_id=user_id,
        total_amount=total_amount,
        status="completed" if order_data.payment_method else "pending",
        payment_status="paid" if order_data.payment_method else "pending",
        payment_method=order_data.payment_method,
        notes=order_data.notes
    )
    db.add(new_order)
    await db.flush()  # Get ID
    
    # 3. Create Items & Update Stock
    for item_data in items_to_create:
        product = item_data["product"]
        
        # Create OrderItem
        order_item = OrderItem(
            order_id=new_order.id,
            product_id=product.id,
            quantity=item_data["quantity"],
            unit_price=item_data["unit_price"],
            total_price=item_data["total_price"],
            product_name=product.name,
            sku=product.sku
        )
        db.add(order_item)
        
        # Update Stock
        if product.track_inventory:
            product.stock_quantity -= item_data["quantity"]
            # Trigger low stock alert logic here if needed
            
    # 4. Record Payment (if applicable)
    if order_data.payment_method:
        payment = Payment(
            organization_id=org_id,
            order_id=new_order.id,
            amount=total_amount,
            payment_method=order_data.payment_method,
            status="completed",
            transaction_id=f"TXN-{new_order.id[:8]}"
        )
        db.add(payment)
        
    await db.commit()
    await db.refresh(new_order)
    
    # Reload with relations for response
    return await get_order(new_order.id, db, token)


# ═══════════════════════════════════════════════════════════════
# REFUND ORDER
# ═══════════════════════════════════════════════════════════════

@router.post("/{order_id}/refund", response_model=OrderResponse)
async def refund_order(
    order_id: str,
    reason: str = Query(..., min_length=3),
    db: AsyncSession = Depends(get_db),
    token: HTTPAuthorizationCredentials = Depends(security)
):
    """
    💸 REFUND ORDER
    
    - Marks order as refunded
    - Restores stock
    - Records refund transaction
    """
    payload = verify_token(token.credentials)
    org_id = payload.get("organization_id")
    
    # Get order with items
    query = (
        select(Order)
        .options(selectinload(Order.items))
        .where(and_(Order.id == order_id, Order.organization_id == org_id))
    )
    result = await db.execute(query)
    order = result.scalar_one_or_none()
    
    if not order:
        raise HTTPException(404, "Order not found")
        
    if order.status == "refunded":
        raise HTTPException(400, "Order already refunded")
        
    # Restore Stock
    for item in order.items:
        result = await db.execute(select(Product).where(Product.id == item.product_id))
        product = result.scalar_one_or_none()
        if product and product.track_inventory:
            product.stock_quantity += item.quantity
            
    # Update Order Status
    order.status = "refunded"
    order.payment_status = "refunded"
    order.notes = f"{order.notes or ''} | Refunded: {reason}"
    
    # Record Status History
    history = OrderStatusHistory(
        order_id=order.id,
        to_status="refunded",
        notes=reason,
        created_by=payload.get("sub")
    )
    db.add(history)
    
    await db.commit()
    await db.refresh(order)
    
    return await get_order(order.id, db, token)
