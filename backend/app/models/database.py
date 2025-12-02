"""
🏢 ENTERPRISE E-COMMERCE DATABASE SCHEMA
A101.com / Amazon / Trendyol Level Super App

Multi-tenant, Marketplace, Vendor Management, Complete E-commerce
"""

from datetime import datetime
from sqlalchemy import (
    Column, String, Float, Integer, Boolean, DateTime, 
    ForeignKey, Text, Enum, JSON, Numeric, Date, Time, Index
)
from sqlalchemy.orm import relationship
from sqlalchemy.ext.declarative import declarative_base
import enum
import uuid

Base = declarative_base()

def generate_uuid():
    return str(uuid.uuid4())


# ═══════════════════════════════════════════════════════════════
# SECTION 1: MULTI-TENANCY & ORGANIZATION
# ═══════════════════════════════════════════════════════════════

class SubscriptionPlan(str, enum.Enum):
    FREE = "free"
    STARTER = "starter"
    BUSINESS = "business"
    ENTERPRISE = "enterprise"
    UNLIMITED = "unlimited"


class Organization(Base):
    """Organizations - Multi-tenant support"""
    __tablename__ = "organizations"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    name = Column(String(255), nullable=False, index=True)
    slug = Column(String(100), unique=True, index=True)
    
    # Contact
    tax_number = Column(String(50), index=True)
    email = Column(String(255))
    phone = Column(String(20))
    website = Column(String(255))
    
    # Address
    address = Column(Text)
    city = Column(String(100))
    state = Column(String(100))
    country = Column(String(100), default="TR")
    postal_code = Column(String(20))
    
    # Subscription
    plan = Column(Enum(SubscriptionPlan), default=SubscriptionPlan.STARTER)
    plan_expires_at = Column(DateTime)
    is_active = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=False)
    
    # Limits
    max_branches = Column(Integer, default=1)
    max_users = Column(Integer, default=5)
    max_products = Column(Integer, default=1000)
    max_storage_gb = Column(Integer, default=10)
    
    # Settings
    settings = Column(JSON, default={})  # Custom settings
    logo_url = Column(String(500))
    banner_url = Column(String(500))
    
    created_at = Column(DateTime, default=datetime.utcnow, index=True)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class Branch(Base):
    """Branches/Stores - Physical or virtual locations"""
    __tablename__ = "branches"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    organization_id = Column(String, ForeignKey("organizations.id"), nullable=False, index=True)
    
    name = Column(String(255), nullable=False)
    code = Column(String(50), index=True)
    branch_type = Column(String(50))  # physical, warehouse, virtual
    
    # Contact
    phone = Column(String(20))
    email = Column(String(255))
    manager_name = Column(String(255))
    
    # Location
    address = Column(Text)
    city = Column(String(100))
    state = Column(String(100))
    postal_code = Column(String(20))
    latitude = Column(Float)
    longitude = Column(Float)
    
    # Operation
    opening_hours = Column(JSON)  # {"monday": "09:00-21:00", ...}
    is_active = Column(Boolean, default=True)
    
    created_at = Column(DateTime, default=datetime.utcnow)


# ═══════════════════════════════════════════════════════════════
# SECTION 2: USERS & AUTHENTICATION
# ═══════════════════════════════════════════════════════════════

class UserRole(str, enum.Enum):
    SUPER_ADMIN = "super_admin"
    ORG_ADMIN = "org_admin"
    MANAGER = "manager"
    CASHIER = "cashier"
    VENDOR = "vendor"
    CUSTOMER = "customer"
    SUPPORT = "support"


class User(Base):
    """Users with RBAC"""
    __tablename__ = "users"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    organization_id = Column(String, ForeignKey("organizations.id"), index=True)
    
    email = Column(String(255), unique=True, nullable=False, index=True)
    phone = Column(String(20), index=True)
    hashed_password = Column(String(255), nullable=False)
    
    # Profile
    first_name = Column(String(100))
    last_name = Column(String(100))
    avatar_url = Column(String(500))
    date_of_birth = Column(Date)
    gender = Column(String(20))
    
    # Access
    role = Column(Enum(UserRole), default=UserRole.CUSTOMER)
    is_active = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=False)
    is_email_verified = Column(Boolean, default=False)
    is_phone_verified = Column(Boolean, default=False)
    
    # Activity
    last_login_at = Column(DateTime)
    last_login_ip = Column(String(50))
    failed_login_attempts = Column(Integer, default=0)
    
    # Settings
    preferences = Column(JSON, default={})
    notification_settings = Column(JSON, default={})
    
    created_at = Column(DateTime, default=datetime.utcnow, index=True)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    __table_args__ = (
        Index('idx_user_org_role', 'organization_id', 'role'),
    )


# ═══════════════════════════════════════════════════════════════
# SECTION 3: VENDORS & SUPPLIERS (Marketplace)
# ═══════════════════════════════════════════════════════════════

class VendorStatus(str, enum.Enum):
    PENDING = "pending"
    APPROVED = "approved"
    SUSPENDED = "suspended"
    REJECTED = "rejected"


class Vendor(Base):
    """Vendors/Suppliers for marketplace"""
    __tablename__ = "vendors"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    organization_id = Column(String, ForeignKey("organizations.id"), index=True)
    user_id = Column(String, ForeignKey("users.id"))  # Vendor owner
    
    company_name = Column(String(255), nullable=False, index=True)
    legal_name = Column(String(255))
    tax_number = Column(String(50))
    trade_registry_number = Column(String(100))
    
    # Contact
    email = Column(String(255))
    phone = Column(String(20))
    website = Column(String(255))
    
    # Address
    address = Column(Text)
    city = Column(String(100))
    state = Column(String(100))
    postal_code = Column(String(20))
    
    # Business
    business_type = Column(String(50))  # retail, wholesale, manufacturer
    commission_rate = Column(Float, default=15.0)  # Marketplace commission %
    
    # Banking
    bank_name = Column(String(100))
    bank_account_number = Column(String(100))
    iban = Column(String(100))
    
    # Status
    status = Column(Enum(VendorStatus), default=VendorStatus.PENDING)
    rating = Column(Float, default=0)
    total_sales = Column(Numeric(15, 2), default=0)
    
    # Settings
    logo_url = Column(String(500))
    banner_url = Column(String(500))
    description = Column(Text)
    return_policy = Column(Text)
    shipping_policy = Column(Text)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    approved_at = Column(DateTime)


# ═══════════════════════════════════════════════════════════════
# SECTION 4: PRODUCT CATALOG (Advanced)
# ═══════════════════════════════════════════════════════════════

class Category(Base):
    """Product categories - Hierarchical"""
    __tablename__ = "categories"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    organization_id = Column(String, ForeignKey("organizations.id"), index=True)
    parent_id = Column(String, ForeignKey("categories.id"), index=True)
    
    name = Column(String(255), nullable=False, index=True)
    slug = Column(String(255), index=True)
    description = Column(Text)
    
    image_url = Column(String(500))
    icon_name = Column(String(100))
    
    sort_order = Column(Integer, default=0)
    is_active = Column(Boolean, default=True)
    is_featured = Column(Boolean, default=False)
    
    seo_title = Column(String(255))
    seo_description = Column(Text)
    seo_keywords = Column(Text)
    
    created_at = Column(DateTime, default=datetime.utcnow)


class Brand(Base):
    """Product brands"""
    __tablename__ = "brands"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    organization_id = Column(String, ForeignKey("organizations.id"), index=True)
    
    name = Column(String(255), nullable=False, index=True)
    slug = Column(String(255), index=True)
    description = Column(Text)
    logo_url = Column(String(500))
    website = Column(String(255))
    
    is_active = Column(Boolean, default=True)
    is_featured = Column(Boolean, default=False)
    
    created_at = Column(DateTime, default=datetime.utcnow)


class Product(Base):
    """Products - Full e-commerce support"""
    __tablename__ = "products"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    organization_id = Column(String, ForeignKey("organizations.id"), nullable=False, index=True)
    vendor_id = Column(String, ForeignKey("vendors.id"), index=True)  # Null = own product
    category_id = Column(String, ForeignKey("categories.id"), index=True)
    brand_id = Column(String, ForeignKey("brands.id"), index=True)
    
    # Basic Info
    name = Column(String(500), nullable=False, index=True)
    slug = Column(String(500), index=True)
    sku = Column(String(100), unique=True, index=True)
    barcode = Column(String(100), index=True)
    
    # Content
    short_description = Column(Text)
    description = Column(Text)
    specifications = Column(JSON)  # {"weight": "500g", "color": "red"}
    
    # Pricing
    base_price = Column(Numeric(15, 2), nullable=False)
    sale_price = Column(Numeric(15, 2))
    cost_price = Column(Numeric(15, 2))
    vat_rate = Column(Float, default=18.0)
    margin_percentage = Column(Float)
    
    # Inventory
    track_inventory = Column(Boolean, default=True)
    stock_quantity = Column(Integer, default=0)
    low_stock_threshold = Column(Integer, default=10)
    allow_backorder = Column(Boolean, default=False)
    
    # Physical
    weight = Column(Float)  # kg
    length = Column(Float)  # cm
    width = Column(Float)
    height = Column(Float)
    
    # Status
    is_active = Column(Boolean, default=True)
    is_featured = Column(Boolean, default=False)
    is_best_seller = Column(Boolean, default=False)
    is_new_arrival = Column(Boolean, default=False)
    
    # SEO
    seo_title = Column(String(255))
    seo_description = Column(Text)
    seo_keywords = Column(Text)
    
    # Stats
    view_count = Column(Integer, default=0)
    sales_count = Column(Integer, default=0)
    rating_avg = Column(Float, default=0)
    review_count = Column(Integer, default=0)
    
    created_at = Column(DateTime, default=datetime.utcnow, index=True)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    __table_args__ = (
        Index('idx_product_search', 'name', 'sku', 'barcode'),
        Index('idx_product_vendor_active', 'vendor_id', 'is_active'),
    )


class ProductVariant(Base):
    """Product variants (size, color, etc.)"""
    __tablename__ = "product_variants"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    product_id = Column(String, ForeignKey("products.id"), nullable=False, index=True)
    
    sku = Column(String(100), unique=True, index=True)
    barcode = Column(String(100))
    
    # Variant attributes
    variant_name = Column(String(255))  # "Red - XL"
    attributes = Column(JSON)  # {"color": "red", "size": "XL"}
    
    # Pricing (override product)
    price_adjustment = Column(Numeric(15, 2), default=0)
    
    # Inventory
    stock_quantity = Column(Integer, default=0)
    
    is_active = Column(Boolean, default=True)
    is_default = Column(Boolean, default=False)
    
    created_at = Column(DateTime, default=datetime.utcnow)


class ProductImage(Base):
    """Product images"""
    __tablename__ = "product_images"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    product_id = Column(String, ForeignKey("products.id"), nullable=False, index=True)
    variant_id = Column(String, ForeignKey("product_variants.id"), index=True)
    
    url = Column(String(500), nullable=False)
    alt_text = Column(String(255))
    sort_order = Column(Integer, default=0)
    is_primary = Column(Boolean, default=False)
    
    created_at = Column(DateTime, default=datetime.utcnow)


# ═══════════════════════════════════════════════════════════════
# SECTION 5: INVENTORY & WAREHOUSES
# ═══════════════════════════════════════════════════════════════

class Warehouse(Base):
    """Warehouses for inventory management"""
    __tablename__ = "warehouses"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    organization_id = Column(String, ForeignKey("organizations.id"), index=True)
    branch_id = Column(String, ForeignKey("branches.id"), index=True)
    
    name = Column(String(255), nullable=False)
    code = Column(String(50))
    
    address = Column(Text)
    city = Column(String(100))
    manager_name = Column(String(255))
    phone = Column(String(20))
    
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)


class StockMovementType(str, enum.Enum):
    PURCHASE = "purchase"  # Buying stock
    SALE = "sale"  # Selling
    RETURN = "return"  # Customer return
    ADJUSTMENT = "adjustment"  # Manual adjustment
    TRANSFER = "transfer"  # Between warehouses
    DAMAGE = "damage"  # Damaged goods
    LOSS = "loss"  # Lost/stolen


class StockMovement(Base):
    """Stock movement tracking"""
    __tablename__ = "stock_movements"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    product_id = Column(String, ForeignKey("products.id"), nullable=False, index=True)
    variant_id = Column(String, ForeignKey("product_variants.id"), index=True)
    warehouse_id = Column(String, ForeignKey("warehouses.id"), index=True)
    user_id = Column(String, ForeignKey("users.id"))
    
    movement_type = Column(Enum(StockMovementType), nullable=False)
    quantity = Column(Integer, nullable=False)  # Positive = in, Negative = out
    
    unit_cost = Column(Numeric(15, 2))
    reference_number = Column(String(100))  # Order ID, PO number, etc.
    notes = Column(Text)
    
    created_at = Column(DateTime, default=datetime.utcnow, index=True)
    
    __table_args__ = (
        Index('idx_stock_movement_product_date', 'product_id', 'created_at'),
    )


# ═══════════════════════════════════════════════════════════════
# SECTION 6: CUSTOMERS (Advanced)
# ═══════════════════════════════════════════════════════════════

class CustomerSegment(str, enum.Enum):
    VIP = "vip"
    REGULAR = "regular"
    NEW = "new"
    INACTIVE = "inactive"
    BLACKLIST = "blacklist"


class Customer(Base):
    """Customers with loyalty & segments"""
    __tablename__ = "customers"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    organization_id = Column(String, ForeignKey("organizations.id"), index=True)
    user_id = Column(String, ForeignKey("users.id"), unique=True)  # Link to auth
    
    # Personal
    first_name = Column(String(100))
    last_name = Column(String(100))
    email = Column(String(255), index=True)
    phone = Column(String(20), index=True)
    date_of_birth = Column(Date)
    gender = Column(String(20))
    
    # Business
    company_name = Column(String(255))
    tax_number = Column(String(50))
    
    # Loyalty
   segment = Column(Enum(CustomerSegment), default=CustomerSegment.NEW)
    loyalty_points = Column(Integer, default=0)
    lifetime_value = Column(Numeric(15, 2), default=0)
    total_orders = Column(Integer, default=0)
    total_spent = Column(Numeric(15, 2), default=0)
    
    # Credit
    credit_limit = Column(Numeric(15, 2), default=0)
    current_balance = Column(Numeric(15, 2), default=0)
    
    # Marketing
    allow_marketing_email = Column(Boolean, default=True)
    allow_marketing_sms = Column(Boolean, default=True)
    
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow, index=True)
    last_purchase_at = Column(DateTime)
    
    __table_args__ = (
        Index('idx_customer_segment_active', 'segment', 'is_active'),
    )


class CustomerAddress(Base):
    """Customer shipping/billing addresses"""
    __tablename__ = "customer_addresses"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    customer_id = Column(String, ForeignKey("customers.id"), nullable=False, index=True)
    
    address_type = Column(String(50))  # shipping, billing
    label = Column(String(100))  # Home, Office, etc.
    
    first_name = Column(String(100))
    last_name = Column(String(100))
    phone = Column(String(20))
    
    address_line1 = Column(String(500))
    address_line2 = Column(String(500))
    city = Column(String(100))
    state = Column(String(100))
    postal_code = Column(String(20))
    country = Column(String(100), default="TR")
    
    is_default = Column(Boolean, default=False)
    

    created_at = Column(DateTime, default=datetime.utcnow)


# ═══════════════════════════════════════════════════════════════
# SECTION 7: ORDERS (Complete E-commerce)
# ═══════════════════════════════════════════════════════════════

class OrderStatus(str, enum.Enum):
    PENDING = "pending"
    CONFIRMED = "confirmed"
    PROCESSING = "processing"
    SHIPPED = "shipped"
    DELIVERED = "delivered"
    CANCELLED = "cancelled"
    RETURNED = "returned"
    REFUNDED = "refunded"
    FAILED = "failed"


class Order(Base):
    """Orders - Full e-commerce"""
    __tablename__ = "orders"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    organization_id = Column(String, ForeignKey("organizations.id"), index=True)
    customer_id = Column(String, ForeignKey("customers.id"), index=True)
    branch_id = Column(String, ForeignKey("branches.id"), index=True)
    
    # Order Info
    order_number = Column(String(50), unique=True, index=True)
    channel = Column(String(50))  # web, mobile, pos, marketplace
    
    # Amounts
    subtotal = Column(Numeric(15, 2), nullable=False)
    tax_amount = Column(Numeric(15, 2), default=0)
    shipping_cost = Column(Numeric(15, 2), default=0)
    discount_amount = Column(Numeric(15, 2), default=0)
    coupon_discount = Column(Numeric(15, 2), default=0)
    total_amount = Column(Numeric(15, 2), nullable=False)
    
    # Discount
    discount_code = Column(String(100))
    discount_type = Column(String(50))
    
    # Customer Info (snapshot)
    customer_email = Column(String(255))
    customer_phone = Column(String(20))
    customer_name = Column(String(255))
    
    # Address (snapshot)
    shipping_address = Column(JSON)
    billing_address = Column(JSON)
    
    # Status
    status = Column(Enum(OrderStatus), default=OrderStatus.PENDING, index=True)
    payment_status = Column(String(50))  # pending, paid, failed, refunded
    fulfillment_status = Column(String(50))  # unfulfilled, partial, fulfilled
    
    # Notes
    customer_notes = Column(Text)
    internal_notes = Column(Text)
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow, index=True)
    confirmed_at = Column(DateTime)
    shipped_at = Column(DateTime)
    delivered_at = Column(DateTime)
    cancelled_at = Column(DateTime)
    
    __table_args__ = (
        Index('idx_order_customer_status', 'customer_id', 'status'),
        Index('idx_order_date_status', 'created_at', 'status'),
    )


class OrderItem(Base):
    """Order line items"""
    __tablename__ = "order_items"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    order_id = Column(String, ForeignKey("orders.id"), nullable=False, index=True)
    product_id = Column(String, ForeignKey("products.id"), index=True)
    variant_id = Column(String, ForeignKey("product_variants.id"))
    vendor_id = Column(String, ForeignKey("vendors.id"), index=True)
    
    # Product snapshot
    product_name = Column(String(500))
    sku = Column(String(100))
    variant_name = Column(String(255))
    image_url = Column(String(500))
    
    # Pricing
    quantity = Column(Integer, nullable=False)
    unit_price = Column(Numeric(15, 2), nullable=False)
    discount_amount = Column(Numeric(15, 2), default=0)
    tax_rate = Column(Float, default=18.0)
    total_price = Column(Numeric(15, 2), nullable=False)
    
    # Vendor commission
    vendor_commission = Column(Numeric(15, 2))
    vendor_payout = Column(Numeric(15, 2))
    
    # Status
    status = Column(String(50))  # pending, shipped, delivered, returned
    
    created_at = Column(DateTime, default=datetime.utcnow)


class OrderStatusHistory(Base):
    """Order status change tracking"""
    __tablename__ = "order_status_history"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    order_id = Column(String, ForeignKey("orders.id"), nullable=False, index=True)
    user_id = Column(String, ForeignKey("users.id"))
    
    from_status = Column(String(50))
    to_status = Column(String(50), nullable=False)
    notes = Column(Text)
    
    created_at = Column(DateTime, default=datetime.utcnow)


# ═══════════════════════════════════════════════════════════════
# SECTION 8: PAYMENTS (Multi-payment, Installments)
# ═══════════════════════════════════════════════════════════════

class PaymentMethod(str, enum.Enum):
    CASH = "cash"
    CREDIT_CARD = "credit_card"
    DEBIT_CARD = "debit_card"
    BANK_TRANSFER = "bank_transfer"
    WALLET = "wallet"
    CREDIT = "credit"
    INSTALLMENT = "installment"
    CRYPTO = "crypto"


class PaymentStatus(str, enum.Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"
    REFUNDED = "refunded"
    PARTIALLY_REFUNDED = "partially_refunded"


class Payment(Base):
    """Payment transactions"""
    __tablename__ = "payments"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    order_id = Column(String, ForeignKey("orders.id"), nullable=False, index=True)
    customer_id = Column(String, ForeignKey("customers.id"), index=True)
    
    # Payment Info
    method = Column(Enum(PaymentMethod), nullable=False)
    amount = Column(Numeric(15, 2), nullable=False)
    currency = Column(String(10), default="TRY")
    
    # Provider (Stripe, PayPal, Iyzico, etc.)
    provider = Column(String(50))
    provider_transaction_id = Column(String(255), index=True)
    provider_response = Column(JSON)
    
    # Card Info (masked)
    card_last4 = Column(String(4))
    card_brand = Column(String(50))
    card_holder_name = Column(String(255))
    
    # Installment
    installment_count = Column(Integer, default=1)
    installment_amount = Column(Numeric(15, 2))
    
    # Status
    status = Column(Enum(PaymentStatus), default=PaymentStatus.PENDING, index=True)
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow, index=True)
    completed_at = Column(DateTime)
    failed_at = Column(DateTime)
    
    # Details
    error_message = Column(Text)
    notes = Column(Text)


class Refund(Base):
    """Refund transactions"""
    __tablename__ = "refunds"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    order_id = Column(String, ForeignKey("orders.id"), nullable=False, index=True)
    payment_id = Column(String, ForeignKey("payments.id"), index=True)
    processed_by = Column(String, ForeignKey("users.id"))
    
    amount = Column(Numeric(15, 2), nullable=False)
    reason = Column(String(255))
    notes = Column(Text)
    
    status = Column(String(50))  # pending, completed, failed
    provider_refund_id = Column(String(255))
    
    created_at = Column(DateTime, default=datetime.utcnow)
    processed_at = Column(DateTime)


# ═══════════════════════════════════════════════════════════════
# SECTION 9: SHIPPING & LOGISTICS
# ═══════════════════════════════════════════════════════════════

class ShippingProvider(Base):
    """Shipping/Cargo providers (Yurtiçi, Aras, MNG, etc.)"""
    __tablename__ = "shipping_providers"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    organization_id = Column(String, ForeignKey("organizations.id"), index=True)
    
    name = Column(String(255), nullable=False)
    code = Column(String(50))
    
    # API Integration
    api_url = Column(String(500))
    api_key = Column(String(500))
    api_secret = Column(String(500))
    
    # Settings
    tracking_url_template = Column(String(500))  # https://track.com/{tracking_number}
    is_active = Column(Boolean, default=True)
    
    created_at = Column(DateTime, default=datetime.utcnow)


class ShippingRate(Base):
    """Shipping rates by weight/region"""
    __tablename__ = "shipping_rates"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    provider_id = Column(String, ForeignKey("shipping_providers.id"), index=True)
    
    # Coverage
    from_city = Column(String(100))
    to_city = Column(String(100))
    to_state = Column(String(100))
    
    # Weight ranges (kg)
    min_weight = Column(Float, default=0)
    max_weight = Column(Float)
    
    # Pricing
    base_rate = Column(Numeric(10, 2), nullable=False)
    per_kg_rate = Column(Numeric(10, 2))
    
    # Delivery
    estimated_days_min = Column(Integer)
    estimated_days_max = Column(Integer)
    
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)


class Shipment(Base):
    """Shipments/Cargo tracking"""
    __tablename__ = "shipments"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    order_id = Column(String, ForeignKey("orders.id"), nullable=False, index=True)
    provider_id = Column(String, ForeignKey("shipping_providers.id"))
    warehouse_id = Column(String, ForeignKey("warehouses.id"))
    
    tracking_number = Column(String(255), unique=True, index=True)
    
    # Shipping Address (snapshot)
    shipping_address = Column(JSON)
    
    # Package
    weight = Column(Float)  # kg
    dimensions = Column(JSON)  # {length, width, height}
    
    # Cost
    shipping_cost = Column(Numeric(10, 2))
    
    # Status
    status = Column(String(50))  # pending, picked_up, in_transit, delivered
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    picked_up_at = Column(DateTime)
    delivered_at = Column(DateTime)
    estimated_delivery_at = Column(DateTime)
    
    notes = Column(Text)


class ShipmentTracking(Base):
    """Shipment tracking events"""
    __tablename__ = "shipment_tracking"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    shipment_id = Column(String, ForeignKey("shipments.id"), nullable=False, index=True)
    
    status = Column(String(100))
    location = Column(String(255))
    description = Column(Text)
    
    event_time = Column(DateTime, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)


# ═══════════════════════════════════════════════════════════════
# SECTION 10: RETURNS & REFUNDS
# ═══════════════════════════════════════════════════════════════

class ReturnReason(str, enum.Enum):
    DEFECTIVE = "defective"
    WRONG_ITEM = "wrong_item"
    NOT_AS_DESCRIBED = "not_as_described"
    CHANGED_MIND = "changed_mind"
    DAMAGED = "damaged"
    OTHER = "other"


class ReturnRequest(Base):
    """Customer return/refund requests"""
    __tablename__ = "return_requests"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    order_id = Column(String, ForeignKey("orders.id"), nullable=False, index=True)
    customer_id = Column(String, ForeignKey("customers.id"), index=True)
    
    return_number = Column(String(50), unique=True, index=True)
    
    # Reason
    reason = Column(Enum(ReturnReason), nullable=False)
    description = Column(Text)
    images = Column(JSON)  # Evidence photos
    
    # Items
    items_json = Column(JSON)  # List of order items to return
    
    # Amounts
    subtotal = Column(Numeric(15, 2))
    shipping_refund = Column(Numeric(15, 2), default=0)
    total_refund = Column(Numeric(15, 2))
    
    # Status
    status = Column(String(50))  # pending, approved, rejected, completed
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow, index=True)
    approved_at = Column(DateTime)
    rejected_at = Column(DateTime)
    completed_at = Column(DateTime)
    
    # Staff handling
    processed_by = Column(String, ForeignKey("users.id"))
    resolution_notes = Column(Text)


# ═══════════════════════════════════════════════════════════════
# SECTION 11: MARKETING & CAMPAIGNS
# ═══════════════════════════════════════════════════════════════

class CampaignType(str, enum.Enum):
    PERCENTAGE_DISCOUNT = "percentage_discount"
    FIXED_DISCOUNT = "fixed_discount"
    BUY_X_GET_Y = "buy_x_get_y"
    FREE_SHIPPING = "free_shipping"
    FLASH_SALE = "flash_sale"
    BUNDLE = "bundle"


class Campaign(Base):
    """Marketing campaigns"""
    __tablename__ = "campaigns"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    organization_id = Column(String, ForeignKey("organizations.id"), index=True)
    
    name = Column(String(255), nullable=False)
    description = Column(Text)
    type = Column(Enum(CampaignType), nullable=False)
    
    # Discount
    discount_percentage = Column(Float)
    discount_amount = Column(Numeric(10, 2))
    max_discount = Column(Numeric(10, 2))
    
    # Conditions
    min_purchase_amount = Column(Numeric(10, 2))
    applicable_products = Column(JSON)  # Product IDs
    applicable_categories = Column(JSON)  # Category IDs
    applicable_brands = Column(JSON)  # Brand IDs
    
    # Limits
    usage_limit_per_customer = Column(Integer)
    total_usage_limit = Column(Integer)
    current_usage_count = Column(Integer, default=0)
    
    # Schedule
    starts_at = Column(DateTime, nullable=False, index=True)
    ends_at = Column(DateTime, nullable=False, index=True)
    
    # Status
    is_active = Column(Boolean, default=True)
    priority = Column(Integer, default=0)  # Higher = applies first
    
    created_at = Column(DateTime, default=datetime.utcnow)


class DiscountCode(Base):
    """Discount/coupon codes"""
    __tablename__ = "discount_codes"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    organization_id = Column(String, ForeignKey("organizations.id"), index=True)
    campaign_id = Column(String, ForeignKey("campaigns.id"))
    
    code = Column(String(100), unique=True, nullable=False, index=True)
    description = Column(Text)
    
    # Discount
    discount_type = Column(String(50))  # percentage, fixed
    discount_value = Column(Numeric(10, 2), nullable=False)
    max_discount = Column(Numeric(10, 2))
    
    # Conditions
    min_purchase_amount = Column(Numeric(10, 2))
    applicable_products = Column(JSON)
    applicable_customer_segments = Column(JSON)
    
    # Limits
    usage_limit_per_customer = Column(Integer, default=1)
    total_usage_limit = Column(Integer)
    current_usage_count = Column(Integer, default=0)
    
    # Schedule
    starts_at = Column(DateTime)
    expires_at = Column(DateTime, index=True)
    
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)


class CodeUsage(Base):
    """Track discount code usage"""
    __tablename__ = "code_usage"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    code_id = Column(String, ForeignKey("discount_codes.id"), index=True)
    order_id = Column(String, ForeignKey("orders.id"), index=True)
    customer_id = Column(String, ForeignKey("customers.id"), index=True)
    
    discount_amount = Column(Numeric(10, 2))
    
    used_at = Column(DateTime, default=datetime.utcnow)


# ═══════════════════════════════════════════════════════════════
# SECTION 12: COMMUNICATIONS (Email/SMS)
# ═══════════════════════════════════════════════════════════════

class NotificationType(str, enum.Enum):
    EMAIL = "email"
    SMS = "sms"
    PUSH = "push"
    IN_APP = "in_app"


class NotificationTemplate(Base):
    """Email/SMS templates"""
    __tablename__ = "notification_templates"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    organization_id = Column(String, ForeignKey("organizations.id"), index=True)
    
    name = Column(String(255), nullable=False)
    code = Column(String(100), unique=True, index=True)  # order_confirmed, shipping_update
    type = Column(Enum(NotificationType), nullable=False)
    
    # Email
    subject = Column(String(500))
    html_body = Column(Text)
    text_body = Column(Text)
    
    # SMS
    sms_body = Column(Text)
    
    # Variables
    available_variables = Column(JSON)  # {customer_name}, {order_number}, etc.
    
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)


class NotificationLog(Base):
    """Notification sending log"""
    __tablename__ = "notification_logs"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    template_id = Column(String, ForeignKey("notification_templates.id"))
    customer_id = Column(String, ForeignKey("customers.id"), index=True)
    order_id = Column(String, ForeignKey("orders.id"), index=True)
    
    type = Column(Enum(NotificationType), nullable=False)
    recipient = Column(String(255))  # email or phone
    
    # Content
    subject = Column(String(500))
    body = Column(Text)
    
    # Status
    status = Column(String(50))  # sent, failed, bounced
    provider = Column(String(100))  # SendGrid, Twilio, etc.
    provider_message_id = Column(String(255))
    error_message = Column(Text)
    
    sent_at = Column(DateTime, default=datetime.utcnow, index=True)
    delivered_at = Column(DateTime)
    opened_at = Column(DateTime)
    clicked_at = Column(DateTime)


# ═══════════════════════════════════════════════════════════════
# SECTION 13: REVIEWS & RATINGS
# ═══════════════════════════════════════════════════════════════

class ProductReview(Base):
    """Product reviews & ratings"""
    __tablename__ = "product_reviews"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    product_id = Column(String, ForeignKey("products.id"), nullable=False, index=True)
    customer_id = Column(String, ForeignKey("customers.id"), index=True)
    order_id = Column(String, ForeignKey("orders.id"), index=True)
    
    # Rating
    rating = Column(Integer, nullable=False)  # 1-5
    title = Column(String(255))
    review_text = Column(Text)
    
    # Media
    images = Column(JSON)  # List of image URLs
    
    # Verification
    is_verified_purchase = Column(Boolean, default=False)
    
    # Moderation
    is_approved = Column(Boolean, default=False)
    is_featured = Column(Boolean, default=False)
    
    # Stats
    helpful_count = Column(Integer, default=0)
    not_helpful_count = Column(Integer, default=0)
    
    created_at = Column(DateTime, default=datetime.utcnow, index=True)
    approved_at = Column(DateTime)


class VendorReview(Base):
    """Vendor reviews"""
    __tablename__ = "vendor_reviews"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    vendor_id = Column(String, ForeignKey("vendors.id"), nullable=False, index=True)
    customer_id = Column(String, ForeignKey("customers.id"), index=True)
    order_id = Column(String, ForeignKey("orders.id"))
    
    # Ratings
    overall_rating = Column(Integer, nullable=False)
    product_quality_rating = Column(Integer)
    shipping_speed_rating = Column(Integer)
    communication_rating = Column(Integer)
    
    review_text = Column(Text)
    
    is_approved = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)


# ═══════════════════════════════════════════════════════════════
# SECTION 14: ANALYTICS & REPORTS
# ═══════════════════════════════════════════════════════════════

class AnalyticsSnapshot(Base):
    """Daily analytics snapshots for fast reporting"""
    __tablename__ = "analytics_snapshots"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    organization_id = Column(String, ForeignKey("organizations.id"), index=True)
    branch_id = Column(String, ForeignKey("branches.id"), index=True)
    
    snapshot_date = Column(Date, nullable=False, index=True)
    
    # Sales
    total_orders = Column(Integer, default=0)
    total_revenue = Column(Numeric(15, 2), default=0)
    total_profit = Column(Numeric(15, 2), default=0)
    average_order_value = Column(Numeric(15, 2))
    
    # Customers
    new_customers = Column(Integer, default=0)
    returning_customers = Column(Integer, default=0)
    
    # Products
    top_products = Column(JSON)
    low_stock_products = Column(JSON)
    
    # Payments
    cash_sales = Column(Numeric(15, 2), default=0)
    card_sales = Column(Numeric(15, 2), default=0)
    credit_sales = Column(Numeric(15, 2), default=0)
    
    # Other
    total_refunds = Column(Numeric(15, 2), default=0)
    total_discounts = Column(Numeric(15, 2), default=0)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    
    __table_args__ = (
        Index('idx_analytics_org_date', 'organization_id', 'snapshot_date'),
    )


# ═══════════════════════════════════════════════════════════════
# SECTION 15: SYSTEM & AUDIT
# ═══════════════════════════════════════════════════════════════

class AuditLog(Base):
    """System audit trail"""
    __tablename__ = "audit_logs"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    organization_id = Column(String, index=True)
    user_id = Column(String, ForeignKey("users.id"), index=True)
    
    action = Column(String(100), nullable=False)  # create, update, delete
    entity_type = Column(String(100))  # product, order, customer
    entity_id = Column(String)
    
    # Changes
    old_values = Column(JSON)
    new_values = Column(JSON)
    
    # Request info
    ip_address = Column(String(50))
    user_agent = Column(String(500))
    
    created_at = Column(DateTime, default=datetime.utcnow, index=True)
    
    __table_args__ = (
        Index('idx_audit_entity', 'entity_type', 'entity_id'),
    )


class SystemSetting(Base):
    """System-wide settings"""
    __tablename__ = "system_settings"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    organization_id = Column(String, ForeignKey("organizations.id"), index=True)
    
    key = Column(String(255), nullable=False, index=True)
    value = Column(JSON)
    data_type = Column(String(50))  # string, number, boolean, json
    
    description = Column(Text)
    is_public = Column(Boolean, default=False)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


# ═══════════════════════════════════════════════════════════════
# CREATE ALL TABLES FUNCTION
# ═══════════════════════════════════════════════════════════════

async def create_all_tables(engine):
    """Create all database tables"""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
        
    print("✅ All database tables created successfully!")
    print(f"📊 Total tables: {len(Base.metadata.tables)}")
    print("\nTables created:")
    for table_name in sorted(Base.metadata.tables.keys()):
        print(f"  ✓ {table_name}")
