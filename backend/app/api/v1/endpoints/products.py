"""
📦 Products API - Complete CRUD Operations
Ultra-fast product management for POS
"""

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, or_, func, update, delete
from typing import List, Optional
from datetime import datetime

from app.db.session import get_db
from app.models.database import Product, ProductVariant, ProductImage, Category, Brand
from app.schemas.schemas import (
    ProductCreate, ProductUpdate, ProductResponse, ProductListResponse
)
from app.core.security import verify_token
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

router = APIRouter(prefix="/products", tags=["Products"])
security = HTTPBearer()


# ═══════════════════════════════════════════════════════════════
# LIST PRODUCTS (with pagination, search, filters)
# ═══════════════════════════════════════════════════════════════

@router.get("", response_model=ProductListResponse)
async def list_products(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    search: Optional[str] = None,
    category_id: Optional[str] = None,
    brand_id: Optional[str] = None,
    is_active: Optional[bool] = None,
    low_stock: bool = False,
    db: AsyncSession = Depends(get_db),
    token: HTTPAuthorizationCredentials = Depends(security)
):
    """
    📋 LIST PRODUCTS
    
    Features:
    - Pagination
    - Search (name, SKU, barcode)
    - Filter by category, brand, status
    - Low stock alert filter
    
    Returns paginated product list
    """
    payload = verify_token(token.credentials)
    org_id = payload.get("organization_id")
    
    # Build query
    conditions = [Product.organization_id == org_id]
    
    # Search
    if search:
        search_condition = or_(
            Product.name.ilike(f"%{search}%"),
            Product.sku.ilike(f"%{search}%"),
            Product.barcode.ilike(f"%{search}%")
        )
        conditions.append(search_condition)
    
    # Filters
    if category_id:
        conditions.append(Product.category_id == category_id)
    if brand_id:
        conditions.append(Product.brand_id == brand_id)
    if is_active is not None:
        conditions.append(Product.is_active == is_active)
    if low_stock:
        conditions.append(Product.stock_quantity <= Product.low_stock_threshold)
    
    # Count total
    count_query = select(func.count(Product.id)).where(and_(*conditions))
    total = (await db.execute(count_query)).scalar()
    
    # Get products
    query = select(Product).where(and_(*conditions)).offset(skip).limit(limit).order_by(Product.created_at.desc())
    result = await db.execute(query)
    products = result.scalars().all()
    
    return ProductListResponse(
        total=total,
        skip=skip,
        limit=limit,
        items=products
    )


# ═══════════════════════════════════════════════════════════════
# GET SINGLE PRODUCT
# ═══════════════════════════════════════════════════════════════

@router.get("/{product_id}", response_model=ProductResponse)
async def get_product(
    product_id: str,
    db: AsyncSession = Depends(get_db),
    token: HTTPAuthorizationCredentials = Depends(security)
):
    """
    🔍 GET PRODUCT DETAILS
    
    Returns complete product information
    """
    payload = verify_token(token.credentials)
    org_id = payload.get("organization_id")
    
    query = select(Product).where(
        and_(
            Product.id == product_id,
            Product.organization_id == org_id
        )
    )
    result = await db.execute(query)
    product = result.scalar_one_or_none()
    
    if not product:
        raise HTTPException(404, "Product not found")
    
    return product


# ═══════════════════════════════════════════════════════════════
# CREATE PRODUCT
# ═══════════════════════════════════════════════════════════════

@router.post("", response_model=ProductResponse, status_code=201)
async def create_product(
    product_data: ProductCreate,
    db: AsyncSession = Depends(get_db),
    token: HTTPAuthorizationCredentials = Depends(security)
):
    """
    ➕ CREATE PRODUCT
    
    Creates new product with all details
    """
    payload = verify_token(token.credentials)
    org_id = payload.get("organization_id")
    
    # Check SKU uniqueness
    existing = await db.execute(
        select(Product).where(
            and_(
                Product.organization_id == org_id,
                Product.sku == product_data.sku
            )
        )
    )
    if existing.scalar_one_or_none():
        raise HTTPException(400, f"Product with SKU '{product_data.sku}' already exists")
    
    # Calculate margin if cost price provided
    margin = None
    if product_data.cost_price:
        margin = ((product_data.base_price - product_data.cost_price) / product_data.base_price) * 100
    
    # Create product
    new_product = Product(
        organization_id=org_id,
        name=product_data.name,
        sku=product_data.sku,
        barcode=product_data.barcode,
        category_id=product_data.category_id,
        brand_id=product_data.brand_id,
        vendor_id=product_data.vendor_id,
        short_description=product_data.short_description,
        description=product_data.description,
        base_price=product_data.base_price,
        sale_price=product_data.sale_price,
        cost_price=product_data.cost_price,
        vat_rate=product_data.vat_rate,
        margin_percentage=margin,
        stock_quantity=product_data.stock_quantity,
        low_stock_threshold=product_data.low_stock_threshold,
        weight=product_data.weight,
        length=product_data.length,
        width=product_data.width,
        height=product_data.height,
        is_active=product_data.is_active,
        is_featured=product_data.is_featured,
        track_inventory=True
    )
    
    db.add(new_product)
    await db.commit()
    await db.refresh(new_product)
    
    return new_product


# ═══════════════════════════════════════════════════════════════
# UPDATE PRODUCT
# ═══════════════════════════════════════════════════════════════

@router.put("/{product_id}", response_model=ProductResponse)
async def update_product(
    product_id: str,
    product_data: ProductUpdate,
    db: AsyncSession = Depends(get_db),
    token: HTTPAuthorizationCredentials = Depends(security)
):
    """
    ✏️ UPDATE PRODUCT
    
    Updates product fields (partial update supported)
    """
    payload = verify_token(token.credentials)
    org_id = payload.get("organization_id")
    
    # Get product
    query = select(Product).where(
        and_(
            Product.id == product_id,
            Product.organization_id == org_id
        )
    )
    result = await db.execute(query)
    product = result.scalar_one_or_none()
    
    if not product:
        raise HTTPException(404, "Product not found")
    
    # Update fields
    update_data = product_data.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(product, field, value)
    
    product.updated_at = datetime.utcnow()
    
    await db.commit()
    await db.refresh(product)
    
    return product


# ═══════════════════════════════════════════════════════════════
# DELETE PRODUCT
# ═══════════════════════════════════════════════════════════════

@router.delete("/{product_id}", status_code=204)
async def delete_product(
    product_id: str,
    db: AsyncSession = Depends(get_db),
    token: HTTPAuthorizationCredentials = Depends(security)
):
    """
    🗑️ DELETE PRODUCT
    
    Soft delete (marks as inactive) or hard delete
    """
    payload = verify_token(token.credentials)
    org_id = payload.get("organization_id")
    
    # Get product
    query = select(Product).where(
        and_(
            Product.id == product_id,
            Product.organization_id == org_id
        )
    )
    result = await db.execute(query)
    product = result.scalar_one_or_none()
    
    if not product:
        raise HTTPException(404, "Product not found")
    
    # Soft delete (recommended)
    product.is_active = False
    await db.commit()
    
    # Hard delete (uncomment if needed)
    # await db.delete(product)
    # await db.commit()
    
    return None


# ═══════════════════════════════════════════════════════════════
# BULK OPERATIONS
# ═══════════════════════════════════════════════════════════════

@router.post("/bulk-import")
async def bulk_import_products(
    products: List[ProductCreate],
    db: AsyncSession = Depends(get_db),
    token: HTTPAuthorizationCredentials = Depends(security)
):
    """
    📥 BULK IMPORT PRODUCTS
    
    Import multiple products at once (CSV/Excel)
    Returns: { success: count, failed: count, errors: [] }
    """
    payload = verify_token(token.credentials)
    org_id = payload.get("organization_id")
    
    success_count = 0
    failed_count = 0
    errors = []
    
    for idx, product_data in enumerate(products):
        try:
            # Check SKU
            existing = await db.execute(
                select(Product).where(
                    and_(
                        Product.organization_id == org_id,
                        Product.sku == product_data.sku
                    )
                )
            )
            if existing.scalar_one_or_none():
                errors.append(f"Row {idx + 1}: SKU '{product_data.sku}' already exists")
                failed_count += 1
                continue
            
            # Create product
            new_product = Product(
                organization_id=org_id,
                **product_data.dict()
            )
            db.add(new_product)
            success_count += 1
            
        except Exception as e:
            errors.append(f"Row {idx + 1}: {str(e)}")
            failed_count += 1
    
    await db.commit()
    
    return {
        "success": success_count,
        "failed": failed_count,
        "errors": errors
    }


@router.patch("/bulk-update-prices")
async def bulk_update_prices(
    updates: List[dict],  # [{"product_id": "...", "new_price": 100}]
    db: AsyncSession = Depends(get_db),
    token: HTTPAuthorizationCredentials = Depends(security)
):
    """
    💰 BULK UPDATE PRICES
    
    Update prices for multiple products
    """
    payload = verify_token(token.credentials)
    org_id = payload.get("organization_id")
    
    updated_count = 0
    
    for update_item in updates:
        product_id = update_item.get("product_id")
        new_price = update_item.get("new_price")
        
        await db.execute(
            update(Product)
            .where(
                and_(
                    Product.id == product_id,
                    Product.organization_id == org_id
                )
            )
            .values(base_price=new_price, updated_at=datetime.utcnow())
        )
        updated_count += 1
    
    await db.commit()
    
    return {"updated": updated_count}


# ═══════════════════════════════════════════════════════════════
# SPECIAL OPERATIONS
# ═══════════════════════════════════════════════════════════════

@router.post("/{product_id}/activate")
async def activate_product(
    product_id: str,
    db: AsyncSession = Depends(get_db),
    token: HTTPAuthorizationCredentials = Depends(security)
):
    """✅ ACTIVATE PRODUCT"""
    payload = verify_token(token.credentials)
    org_id = payload.get("organization_id")
    
    await db.execute(
        update(Product)
        .where(and_(Product.id == product_id, Product.organization_id == org_id))
        .values(is_active=True)
    )
    await db.commit()
    
    return {"message": "Product activated"}


@router.post("/{product_id}/deactivate")
async def deactivate_product(
    product_id: str,
    db: AsyncSession = Depends(get_db),
    token: HTTPAuthorizationCredentials = Depends(security)
):
    """❌ DEACTIVATE PRODUCT"""
    payload = verify_token(token.credentials)
    org_id = payload.get("organization_id")
    
    await db.execute(
        update(Product)
        .where(and_(Product.id == product_id, Product.organization_id == org_id))
        .values(is_active=False)
    )
    await db.commit()
    
    return {"message": "Product deactivated"}


@router.get("/{product_id}/stock-history")
async def get_stock_history(
    product_id: str,
    limit: int = 50,
    db: AsyncSession = Depends(get_db),
    token: HTTPAuthorizationCredentials = Depends(security)
):
    """
    📊 GET STOCK MOVEMENT HISTORY
    
    Returns stock movement history for product
    """
    from app.models.database import StockMovement
    
    query = select(StockMovement).where(
        StockMovement.product_id == product_id
    ).order_by(StockMovement.created_at.desc()).limit(limit)
    
    result = await db.execute(query)
    movements = result.scalars().all()
    
    return {
        "product_id": product_id,
        "movements": [
            {
                "type": m.movement_type,
                "quantity": m.quantity,
                "unit_cost": float(m.unit_cost) if m.unit_cost else None,
                "reference": m.reference_number,
                "created_at": m.created_at
            }
            for m in movements
        ]
    }
