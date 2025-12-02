"""
📦 Pydantic Schemas - Request/Response Models
"""

from pydantic import BaseModel, EmailStr, Field, validator
from typing import Optional, List
from datetime import datetime
from decimal import Decimal


# ═══════════════════════════════════════════════════════════════
# AUTHENTICATION SCHEMAS
# ═══════════════════════════════════════════════════════════════

class UserRegister(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=8)
    first_name: str = Field(..., min_length=1, max_length=100)
    last_name: str = Field(..., min_length=1, max_length=100)
    phone: Optional[str] = None
    organization_id: Optional[str] = None


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int


class UserResponse(BaseModel):
    id: str
    email: str
    first_name: str
    last_name: str
    role: str
    is_active: bool
    created_at: datetime
    
    class Config:
        from_attributes = True


# ═══════════════════════════════════════════════════════════════
# PRODUCT SCHEMAS
# ═══════════════════════════════════════════════════════════════

class ProductCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=500)
    sku: str = Field(..., min_length=1, max_length=100)
    barcode: Optional[str] = None
    category_id: Optional[str] = None
    brand_id: Optional[str] = None
    vendor_id: Optional[str] = None
    
    short_description: Optional[str] = None
    description: Optional[str] = None
    
    base_price: Decimal = Field(..., gt=0)
    sale_price: Optional[Decimal] = None
    cost_price: Optional[Decimal] = None
    vat_rate: float = 18.0
    
    stock_quantity: int = 0
    low_stock_threshold: int = 10
    
    weight: Optional[float] = None
    length: Optional[float] = None
    width: Optional[float] = None
    height: Optional[float] = None
    
    is_active: bool = True
    is_featured: bool = False


class ProductUpdate(BaseModel):
    name: Optional[str] = None
    base_price: Optional[Decimal] = None
    sale_price: Optional[Decimal] = None
    stock_quantity: Optional[int] = None
    is_active: Optional[bool] = None


class ProductResponse(BaseModel):
    id: str
    name: str
    sku: str
    barcode: Optional[str]
    base_price: Decimal
    sale_price: Optional[Decimal]
    stock_quantity: int
    is_active: bool
    rating_avg: float
    sales_count: int
    created_at: datetime
    
    class Config:
        from_attributes = True


class ProductListResponse(BaseModel):
    total: int
    skip: int
    limit: int
    items: List[ProductResponse]


# ═══════════════════════════════════════════════════════════════
# ORDER SCHEMAS
# ═══════════════════════════════════════════════════════════════

class OrderItemCreate(BaseModel):
    product_id: str
    variant_id: Optional[str] = None
    quantity: int = Field(..., gt=0)
    unit_price: Decimal = Field(..., gt=0)


class OrderCreate(BaseModel):
    customer_id: Optional[str] = None
    branch_id: str
    channel: str = "pos"
    
    items: List[OrderItemCreate]
    
    discount_amount: Decimal = 0
    discount_code: Optional[str] = None
    shipping_cost: Decimal = 0
    
    shipping_address: Optional[dict] = None
    billing_address: Optional[dict] = None
    
    customer_notes: Optional[str] = None


class OrderResponse(BaseModel):
    id: str
    order_number: str
    customer_id: Optional[str]
    status: str
    
    subtotal: Decimal
    tax_amount: Decimal
    shipping_cost: Decimal
    discount_amount: Decimal
    total_amount: Decimal
    
    payment_status: str
    
    created_at: datetime
    
    class Config:
        from_attributes = True


# ═══════════════════════════════════════════════════════════════
# CUSTOMER SCHEMAS
# ═══════════════════════════════════════════════════════════════

class CustomerCreate(BaseModel):
    first_name: str = Field(..., min_length=1, max_length=100)
    last_name: str = Field(..., min_length=1, max_length=100)
    email: Optional[EmailStr] = None
    phone: Optional[str] = None
    company_name: Optional[str] = None
    tax_number: Optional[str] = None


class CustomerResponse(BaseModel):
    id: str
    first_name: str
    last_name: str
    email: Optional[str]
    phone: Optional[str]
    segment: str
    loyalty_points: int
    total_spent: Decimal
    total_orders: int
    created_at: datetime
    
    class Config:
        from_attributes = True


# ═══════════════════════════════════════════════════════════════
# ANALYTICS SCHEMAS
# ═══════════════════════════════════════════════════════════════

class DailySalesReport(BaseModel):
    date: str
    total_orders: int
    total_revenue: Decimal
    average_order_value: Decimal
    new_customers: int
    returning_customers: int


class WeeklySalesReport(BaseModel):
    period_start: str
    period_end: str
    daily_sales: List[DailySalesReport]
    total_revenue: Decimal
    growth_rate: float


# ═══════════════════════════════════════════════════════════════
# COMMON SCHEMAS
# ═══════════════════════════════════════════════════════════════

class SuccessResponse(BaseModel):
    success: bool = True
    message: str
    data: Optional[dict] = None


class ErrorResponse(BaseModel):
    success: bool = False
    error: str
    details: Optional[dict] = None


class HealthCheck(BaseModel):
    status: str
    app: str
    version: str
    database: str
    redis: str
