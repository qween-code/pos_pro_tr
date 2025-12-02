"""
🏪 POS-SPECIFIC API ENDPOINTS
Real-time Point of Sale Operations

Core POS Features:
- Fast product scanning (barcode)
- Quick checkout
- Cash register operations
- Receipt printing
- Daily reports (Z-report)
- Stock management
- Customer credit
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, func, update
from typing import List, Optional
from datetime import datetime, date
from decimal import Decimal

from app.db.session import get_db
from app.models.database import (
    Product, Order, OrderItem, Payment, Customer, 
    CashRegister, User, Branch
)
from app.schemas.schemas import (
    ProductResponse, OrderCreate, OrderResponse,
    SuccessResponse
)
from app.core.security import verify_token
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

router = APIRouter(prefix="/pos", tags=["POS Operations"])
security = HTTPBearer()


# ═══════════════════════════════════════════════════════════════
# PRODUCT LOOKUP (Barcode Scan)
# ═══════════════════════════════════════════════════════════════

@router.get("/scan/{barcode}", response_model=ProductResponse)
async def scan_product(
    barcode: str,
    db: AsyncSession = Depends(get_db),
    token: HTTPAuthorizationCredentials = Depends(security)
):
    """
    🔍 BARCODE SCAN - Ultra fast product lookup
    
    Usage: Cashier scans product barcode
    Returns: Product details with current stock & price
    """
    # Verify token
    payload = verify_token(token.credentials)
    org_id = payload.get("organization_id")
    
    # Find product by barcode
    query = select(Product).where(
        and_(
            Product.organization_id == org_id,
            Product.barcode == barcode,
            Product.is_active == True
        )
    )
    result = await db.execute(query)
    product = result.scalar_one_or_none()
    
    if not product:
        raise HTTPException(
            status_code=404,
            detail=f"Product with barcode '{barcode}' not found"
        )
    
    return product


@router.get("/products/search", response_model=List[ProductResponse])
async def search_products(
    q: str,
    limit: int = 20,
    db: AsyncSession = Depends(get_db),
    token: HTTPAuthorizationCredentials = Depends(security)
):
    """
    🔎 QUICK SEARCH - Search products by name/SKU
    
    Usage: Cashier types product name when searching
    """
    payload = verify_token(token.credentials)
    org_id = payload.get("organization_id")
    
    query = select(Product).where(
        and_(
            Product.organization_id == org_id,
            Product.is_active == True,
            (Product.name.ilike(f"%{q}%") | Product.sku.ilike(f"%{q}%"))
        )
    ).limit(limit)
    
    result = await db.execute(query)
    products = result.scalars().all()
    
    return products


# ═══════════════════════════════════════════════════════════════
# QUICK CHECKOUT
# ═══════════════════════════════════════════════════════════════

@router.post("/checkout", response_model=OrderResponse)
async def quick_checkout(
    order_data: OrderCreate,
    db: AsyncSession = Depends(get_db),
    token: HTTPAuthorizationCredentials = Depends(security)
):
    """
    💳 QUICK CHECKOUT - Process sale instantly
    
    Steps:
    1. Validate stock
    2. Calculate totals
    3. Create order
    4. Update stock
    5. Process payment
    6. Return receipt data
    """
    payload = verify_token(token.credentials)
    org_id = payload.get("organization_id")
    user_id = payload.get("sub")
    
    # 1. Validate stock & calculate
    subtotal = Decimal(0)
    tax_amount = Decimal(0)
    order_items_data = []
    
    for item in order_data.items:
        # Get product
        product_query = select(Product).where(Product.id == item.product_id)
        product = (await db.execute(product_query)).scalar_one_or_none()
        
        if not product:
            raise HTTPException(404, f"Product {item.product_id} not found")
        
        # Check stock
        if product.track_inventory and product.stock_quantity < item.quantity:
            raise HTTPException(
                400,
                f"Insufficient stock for {product.name}. Available: {product.stock_quantity}"
            )
        
        # Calculate
        item_total = item.unit_price * item.quantity
        item_tax = item_total * (product.vat_rate / 100)
        
        subtotal += item_total
        tax_amount += item_tax
        
        order_items_data.append({
            "product": product,
            "quantity": item.quantity,
            "unit_price": item.unit_price,
            "tax": item_tax,
            "total": item_total + item_tax
        })
    
    # 2. Calculate final totals
    total = subtotal + tax_amount - order_data.discount_amount + order_data.shipping_cost
    
    # 3. Create order
    order_number = f"ORD-{datetime.now().strftime('%Y%m%d')}-{datetime.now().microsecond}"
    
    new_order = Order(
        organization_id=org_id,
        branch_id=order_data.branch_id,
        customer_id=order_data.customer_id,
        cashier_id=user_id,
        order_number=order_number,
        channel=order_data.channel,
        subtotal=subtotal,
        tax_amount=tax_amount,
        discount_amount=order_data.discount_amount,
        shipping_cost=order_data.shipping_cost,
        total_amount=total,
        status="completed",
        payment_status="paid",
        customer_notes=order_data.customer_notes
    )
    
    db.add(new_order)
    await db.flush()
    
    # 4. Add order items & update stock
    for item_data in order_items_data:
        order_item = OrderItem(
            order_id=new_order.id,
            product_id=item_data["product"].id,
            product_name=item_data["product"].name,
            sku=item_data["product"].sku,
            quantity=item_data["quantity"],
            unit_price=item_data["unit_price"],
            tax_rate=item_data["product"].vat_rate,
            total_price=item_data["total"]
        )
        db.add(order_item)
        
        # Update stock
        if item_data["product"].track_inventory:
            await db.execute(
                update(Product)
                .where(Product.id == item_data["product"].id)
                .values(
                    stock_quantity=Product.stock_quantity - item_data["quantity"],
                    sales_count=Product.sales_count + item_data["quantity"]
                )
            )
    
    # 5. Create payment record
    payment = Payment(
        order_id=new_order.id,
        customer_id=order_data.customer_id,
        method="cash",  # Default, can be from order_data
        amount=total,
        status="completed",
        completed_at=datetime.utcnow()
    )
    db.add(payment)
    
    await db.commit()
    await db.refresh(new_order)
    
    return new_order


# ═══════════════════════════════════════════════════════════════
# CASH REGISTER OPERATIONS
# ═══════════════════════════════════════════════════════════════

@router.post("/register/open", response_model=SuccessResponse)
async def open_register(
    opening_amount: Decimal,
    branch_id: str,
    db: AsyncSession = Depends(get_db),
    token: HTTPAuthorizationCredentials = Depends(security)
):
    """
    🔓 OPEN REGISTER - Start cashier shift
    """
    payload = verify_token(token.credentials)
    org_id = payload.get("organization_id")
    user_id = payload.get("sub")
    
    # Check if already open
    existing = await db.execute(
        select(CashRegister).where(
            and_(
                CashRegister.user_id == user_id,
                CashRegister.status == "open"
            )
        )
    )
    if existing.scalar_one_or_none():
        raise HTTPException(400, "register already open")
    
    register = CashRegister(
        organization_id=org_id,
        branch_id=branch_id,
        user_id=user_id,
        opening_amount=opening_amount,
        status="open",
        opened_at=datetime.utcnow()
    )
    
    db.add(register)
    await db.commit()
    
    return SuccessResponse(
        message="Register opened successfully",
        data={"register_id": register.id}
    )


@router.post("/register/close", response_model=SuccessResponse)
async def close_register(
    closing_amount: Decimal,
    db: AsyncSession = Depends(get_db),
    token: HTTPAuthorizationCredentials = Depends(security)
):
    """
    🔒 CLOSE REGISTER - End cashier shift
    
    Returns: Z-report summary
    """
    payload = verify_token(token.credentials)
    user_id = payload.get("sub")
    
    # Get open register
    result = await db.execute(
        select(CashRegister).where(
            and_(
                CashRegister.user_id == user_id,
                CashRegister.status == "open"
            )
        )
    )
    register = result.scalar_one_or_none()
    
    if not register:
        raise HTTPException(404, "No open register found")
    
    # Calculate sales during shift
    sales_query = select(
        func.count(Order.id).label("total_orders"),
        func.coalesce(func.sum(Order.total_amount), 0).label("total_sales"),
        func.coalesce(func.sum(
            case((Payment.method == "cash", Payment.amount), else_=0)
        ), 0).label("cash_sales"),
        func.coalesce(func.sum(
            case((Payment.method == "card", Payment.amount), else_=0)
        ), 0).label("card_sales")
    ).select_from(Order).join(Payment).where(
        and_(
            Order.cashier_id == user_id,
            Order.created_at >= register.opened_at
        )
    )
    
    sales = (await db.execute(sales_query)).first()
    
    # Update register
    register.closing_amount = closing_amount
    register.cash_sales = sales.cash_sales
    register.card_sales = sales.card_sales
    register.status = "closed"
    register.closed_at = datetime.utcnow()
    
    await db.commit()
    
    # Z-report data
    expected_cash = register.opening_amount + sales.cash_sales
    difference = closing_amount - expected_cash
    
    return SuccessResponse(
        message="Register closed successfully",
        data={
            "register_id": register.id,
            "shift_duration_hours": (register.closed_at - register.opened_at).seconds / 3600,
            "total_orders": sales.total_orders,
            "total_sales": float(sales.total_sales),
            "cash_sales": float(sales.cash_sales),
            "card_sales": float(sales.card_sales),
            "opening_amount": float(register.opening_amount),
            "expected_cash": float(expected_cash),
            "actual_cash": float(closing_amount),
            "difference": float(difference),
            "status": "balanced" if abs(difference) < 0.01 else "variance"
        }
    )


# ═══════════════════════════════════════════════════════════════
# DAILY REPORTS
# ═══════════════════════════════════════════════════════════════

@router.get("/reports/daily")
async def daily_sales_report(
    report_date: Optional[date] = None,
    branch_id: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    token: HTTPAuthorizationCredentials = Depends(security)
):
    """
    📊 DAILY SALES REPORT
    
    Returns: Complete day summary
    """
    payload = verify_token(token.credentials)
    org_id = payload.get("organization_id")
    
    if not report_date:
        report_date = date.today()
    
    # Build query
    conditions = [
        Order.organization_id == org_id,
        func.date(Order.created_at) == report_date,
        Order.status.in_(["completed", "partial_refunded"])
    ]
    
    if branch_id:
        conditions.append(Order.branch_id == branch_id)
    
    # Aggregate query
    stats_query = select(
        func.count(Order.id).label("total_orders"),
        func.coalesce(func.sum(Order.total_amount), 0).label("total_revenue"),
        func.coalesce(func.sum(Order.tax_amount), 0).label("total_tax"),
        func.coalesce(func.sum(Order.discount_amount), 0).label("total_discounts"),
        func.avg(Order.total_amount).label("average_order_value")
    ).where(and_(*conditions))
    
    stats = (await db.execute(stats_query)).first()
    
    # Payment breakdown
    payment_query = select(
        Payment.method,
        func.count(Payment.id).label("count"),
        func.sum(Payment.amount).label("total")
    ).join(Order).where(and_(*conditions)).group_by(Payment.method)
    
    payments = (await db.execute(payment_query)).all()
    
    # Top products
    top_products_query = select(
        Product.name,
        func.sum(OrderItem.quantity).label("quantity_sold"),
        func.sum(OrderItem.total_price).label("revenue")
    ).select_from(OrderItem).join(Order).join(Product).where(
        and_(*conditions)
    ).group_by(Product.id, Product.name).order_by(
        func.sum(OrderItem.total_price).desc()
    ).limit(10)
    
    top_products = (await db.execute(top_products_query)).all()
    
    return {
        "date": str(report_date),
        "summary": {
            "total_orders": stats.total_orders,
            "total_revenue": float(stats.total_revenue),
            "total_tax": float(stats.total_tax),
            "total_discounts": float(stats.total_discounts),
            "average_order_value": float(stats.average_order_value or 0)
        },
        "payment_methods": [
            {
                "method": p.method,
                "count": p.count,
                "total": float(p.total)
            } for p in payments
        ],
        "top_products": [
            {
                "name": p.name,
                "quantity_sold": p.quantity_sold,
                "revenue": float(p.revenue)
            } for p in top_products
        ]
    }


# ═══════════════════════════════════════════════════════════════
# CUSTOMER CREDIT OPERATIONS
# ═══════════════════════════════════════════════════════════════

@router.get("/customers/{customer_id}/credit")
async def get_customer_credit(
    customer_id: str,
    db: AsyncSession = Depends(get_db),
    token: HTTPAuthorizationCredentials = Depends(security)
):
    """
    💳 CHECK CUSTOMER CREDIT
    
    Returns: Current balance and limit
    """
    payload = verify_token(token.credentials)
    org_id = payload.get("organization_id")
    
    customer = await db.execute(
        select(Customer).where(
            and_(
                Customer.id == customer_id,
                Customer.organization_id == org_id
            )
        )
    )
    customer = customer.scalar_one_or_none()
    
    if not customer:
        raise HTTPException(404, "Customer not found")
    
    available_credit = customer.credit_limit - customer.current_balance
    
    return {
        "customer_id": customer.id,
        "customer_name": f"{customer.first_name} {customer.last_name}",
        "credit_limit": float(customer.credit_limit),
        "current_balance": float(customer.current_balance),
        "available_credit": float(available_credit),
        "can_purchase": available_credit > 0
    }


# ═══════════════════════════════════════════════════════════════
# STOCK CHECK
# ═══════════════════════════════════════════════════════════════

@router.get("/stock/low")
async def low_stock_alert(
    limit: int = 50,
    db: AsyncSession = Depends(get_db),
    token: HTTPAuthorizationCredentials = Depends(security)
):
    """
    ⚠️ LOW STOCK ALERT
    
    Returns: Products below critical level
    """
    payload = verify_token(token.credentials)
    org_id = payload.get("organization_id")
    
    query = select(Product).where(
        and_(
            Product.organization_id == org_id,
            Product.is_active == True,
            Product.stock_quantity <= Product.low_stock_threshold
        )
    ).order_by(Product.stock_quantity.asc()).limit(limit)
    
    products = (await db.execute(query)).scalars().all()
    
    return {
        "total_low_stock": len(products),
        "products": [
            {
                "id": p.id,
                "name": p.name,
                "sku": p.sku,
                "current_stock": p.stock_quantity,
                "threshold": p.low_stock_threshold,
                "shortage": p.low_stock_threshold - p.stock_quantity
            } for p in products
        ]
    }
