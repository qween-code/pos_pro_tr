"""
🌍 GLOBAL E-COMMERCE PLATFORM - Database Extension
World-Class System: Amazon + Shopify + Alibaba Combined

Additional Features:
- Multi-currency & Exchange rates
- Multi-language (i18n)
- Global tax systems (VAT/GST by country)
- International shipping
- Subscriptions & Recurring billing
- Digital products & Downloads
- Gift cards & Store credit
- Wishlists & Favorites
- Product bundles
- Pre-orders & Back-in-stock notifications
- Affiliate program
- Social commerce integration
- Live chat & Customer support
- Fraud detection
- A/B Testing
- Advanced analytics
"""

from datetime import datetime
from sqlalchemy import Column, String, Float, Integer, Boolean, DateTime, ForeignKey, Text, JSON, Numeric, Date, Index
from sqlalchemy.orm import relationship
from .database import Base, generate_uuid
import enum


# ═══════════════════════════════════════════════════════════════
# GLOBALIZATION & LOCALIZATION
# ═══════════════════════════════════════════════════════════════

class Currency(Base):
    """Multi-currency support"""
    __tablename__ = "currencies"
    
    code = Column(String(3), primary_key=True)  # USD, EUR, TRY, GBP
    name = Column(String(100))
    symbol = Column(String(10))
    decimal_places = Column(Integer, default=2)
    is_active = Column(Boolean, default=True)
    
    created_at = Column(DateTime, default=datetime.utcnow)


class ExchangeRate(Base):
    """Currency exchange rates (updated daily)"""
    __tablename__ = "exchange_rates"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    from_currency = Column(String(3), ForeignKey("currencies.code"), index=True)
    to_currency = Column(String(3), ForeignKey("currencies.code"), index=True)
    
    rate = Column(Numeric(20, 10), nullable=False)
    
    # Auto-update from API (exchangerate-api.com, fixer.io)
    source = Column(String(100))
    
    effective_date = Column(Date, nullable=False, index=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    __table_args__ = (
        Index('idx_exchange_rate_pair_date', 'from_currency', 'to_currency', 'effective_date'),
    )


class Language(Base):
    """Supported languages"""
    __tablename__ = "languages"
    
    code = Column(String(10), primary_key=True)  # en, tr, de, fr, ar, zh
    name = Column(String(100))
    native_name = Column(String(100))  # "Türkçe", "العربية", "中文"
    direction = Column(String(3), default="ltr")  # ltr or rtl
    is_active = Column(Boolean, default=True)
    
    created_at = Column(DateTime, default=datetime.utcnow)


class Translation(Base):
    """Translations for products, categories, etc."""
    __tablename__ = "translations"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    language_code = Column(String(10), ForeignKey("languages.code"), index=True)
    
    entity_type = Column(String(50), index=True)  # product, category, brand
    entity_id = Column(String, index=True)
    field_name = Column(String(100))  # name, description
    
    translated_text = Column(Text)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    
    __table_args__ = (
        Index('idx_translation_entity', 'entity_type', 'entity_id', 'language_code'),
    )


class Country(Base):
    """Countries for shipping, tax, etc."""
    __tablename__ = "countries"
    
    code = Column(String(2), primary_key=True)  # US, TR, GB, DE
    name = Column(String(255))
    phone_code = Column(String(10))  # +90, +1, +44
    currency_code = Column(String(3), ForeignKey("currencies.code"))
    
    # Tax
    default_tax_rate = Column(Float)
    tax_name = Column(String(50))  # VAT, GST, Sales Tax
    
    is_shipping_available = Column(Boolean, default=True)
    is_active = Column(Boolean, default=True)
    
    created_at = Column(DateTime, default=datetime.utcnow)


class TaxRule(Base):
    """Tax rules by country/region/product"""
    __tablename__ = "tax_rules"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    country_code = Column(String(2), ForeignKey("countries.code"), index=True)
    state = Column(String(100))  # For USA states, etc.
    
    # Product category specific
    category_id = Column(String, ForeignKey("categories.id"))
    
    tax_rate = Column(Float, nullable=False)
    tax_name = Column(String(50))  # "VAT", "GST", "Sales Tax"
    
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)


# ═══════════════════════════════════════════════════════════════
# SUBSCRIPTIONS & RECURRING BILLING
# ═══════════════════════════════════════════════════════════════

class SubscriptionPlanType(str, enum.Enum):
    DAILY = "daily"
    WEEKLY = "weekly"
    MONTHLY = "monthly"
    QUARTERLY = "quarterly"
    YEARLY = "yearly"


class SubscriptionPlan(Base):
    """Subscription/membership plans"""
    __tablename__ = "subscription_plans"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    organization_id = Column(String, ForeignKey("organizations.id"), index=True)
    
    name = Column(String(255), nullable=False)
    description = Column(Text)
    
    # Pricing
    billing_cycle = Column(Enum(SubscriptionPlanType), nullable=False)
    price = Column(Numeric(10, 2), nullable=False)
    currency = Column(String(3), default="USD")
    
    # Trial
    trial_days = Column(Integer, default=0)
    
    # Features (JSON)
    features = Column(JSON)  # {"max_products": 1000, "custom_domain": true}
    
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)


class Subscription(Base):
    """Customer subscriptions"""
    __tablename__ = "subscriptions"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    customer_id = Column(String, ForeignKey("customers.id"), nullable=False, index=True)
    plan_id = Column(String, ForeignKey("subscription_plans.id"), index=True)
    
    status = Column(String(50), index=True)  # active, cancelled, past_due, trialing
    
    # Billing
    current_period_start = Column(DateTime)
    current_period_end = Column(DateTime)
    trial_end = Column(DateTime)
    
    # Payment
    payment_method_id = Column(String)
    
    # Cancellation
    cancel_at = Column(DateTime)
    cancelled_at = Column(DateTime)
    cancellation_reason = Column(Text)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    
    __table_args__ = (
        Index('idx_subscription_customer_status', 'customer_id', 'status'),
    )


# ═══════════════════════════════════════════════════════════════
# DIGITAL PRODUCTS & DOWNLOADS
# ═══════════════════════════════════════════════════════════════

class DigitalProduct(Base):
    """Digital products (ebooks, software, music, etc.)"""
    __tablename__ = "digital_products"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    product_id = Column(String, ForeignKey("products.id"), unique=True, index=True)
    
    # File
    file_url = Column(String(500))  # S3, CloudFront, etc.
    file_size_mb = Column(Float)
    file_type = Column(String(50))  # pdf, zip, mp3, mp4
    
    # Limits
    download_limit = Column(Integer)  # Null = unlimited
    download_expiry_days = Column(Integer, default=30)
    
    # Version
    version = Column(String(50))
    
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class Download(Base):
    """Download tracking"""
    __tablename__ = "downloads"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    digital_product_id = Column(String, ForeignKey("digital_products.id"), index=True)
    customer_id = Column(String, ForeignKey("customers.id"), index=True)
    order_id = Column(String, ForeignKey("orders.id"), index=True)
    
    download_token = Column(String(255), unique=True, index=True)
    
    download_count = Column(Integer, default=0)
    max_downloads = Column(Integer)
    expires_at = Column(DateTime)
    
    ip_address = Column(String(50))
    user_agent = Column(String(500))
    
    created_at = Column(DateTime, default=datetime.utcnow)
    last_downloaded_at = Column(DateTime)


# ═══════════════════════════════════════════════════════════════
# GIFT CARDS & STORE CREDIT
# ═══════════════════════════════════════════════════════════════

class GiftCard(Base):
    """Gift cards / Store credit"""
    __tablename__ = "gift_cards"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    organization_id = Column(String, ForeignKey("organizations.id"), index=True)
    
    code = Column(String(100), unique=True, nullable=False, index=True)
    
    # Value
    initial_value = Column(Numeric(10, 2), nullable=False)
    current_balance = Column(Numeric(10, 2), nullable=False)
    currency = Column(String(3), default="USD")
    
    # Recipient
    recipient_email = Column(String(255))
    recipient_name = Column(String(255))
    message = Column(Text)
    
    # Purchaser
    purchaser_id = Column(String, ForeignKey("customers.id"))
    order_id = Column(String, ForeignKey("orders.id"))
    
    # Validity
    expires_at = Column(DateTime)
    
    # Status
    is_active = Column(Boolean, default=True)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    activated_at = Column(DateTime)
    
    __table_args__ = (
        Index('idx_giftcard_code_active', 'code', 'is_active'),
    )


class GiftCardTransaction(Base):
    """Gift card usage history"""
    __tablename__ = "gift_card_transactions"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    gift_card_id = Column(String, ForeignKey("gift_cards.id"), index=True)
    order_id = Column(String, ForeignKey("orders.id"))
    
    transaction_type = Column(String(50))  # purchase, usage, refund
    amount = Column(Numeric(10, 2), nullable=False)
    balance_after = Column(Numeric(10, 2))
    
    notes = Column(Text)
    
    created_at = Column(DateTime, default=datetime.utcnow)


# ═══════════════════════════════════════════════════════════════
# WISHLISTS & FAVORITES
# ═══════════════════════════════════════════════════════════════

class Wishlist(Base):
    """Customer wishlists"""
    __tablename__ = "wishlists"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    customer_id = Column(String, ForeignKey("customers.id"), nullable=False, index=True)
    
    name = Column(String(255), default="My Wishlist")
    is_public = Column(Boolean, default=False)
    share_token = Column(String(100), unique=True, index=True)
    
    created_at = Column(DateTime, default=datetime.utcnow)


class WishlistItem(Base):
    """Items in wishlist"""
    __tablename__ = "wishlist_items"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    wishlist_id = Column(String, ForeignKey("wishlists.id"), nullable=False, index=True)
    product_id = Column(String, ForeignKey("products.id"), nullable=False, index=True)
    variant_id = Column(String, ForeignKey("product_variants.id"))
    
    notes = Column(Text)
    priority = Column(Integer, default=0)
    
    added_at = Column(DateTime, default=datetime.utcnow)


# ═══════════════════════════════════════════════════════════════
# PRODUCT BUNDLES & KITS
# ═══════════════════════════════════════════════════════════════

class ProductBundle(Base):
    """Product bundles (buy together deals)"""
    __tablename__ = "product_bundles"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    organization_id = Column(String, ForeignKey("organizations.id"), index=True)
    
    name = Column(String(255), nullable=False)
    description = Column(Text)
    
    # Pricing
    bundle_price = Column(Numeric(10, 2))
    discount_percentage = Column(Float)
    
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)


class BundleItem(Base):
    """Products in bundle"""
    __tablename__ = "bundle_items"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    bundle_id = Column(String, ForeignKey("product_bundles.id"), nullable=False, index=True)
    product_id = Column(String, ForeignKey("products.id"), nullable=False)
    
    quantity = Column(Integer, default=1)
    sort_order = Column(Integer, default=0)


# ═══════════════════════════════════════════════════════════════
# PRE-ORDERS & BACK-IN-STOCK NOTIFICATIONS
# ═══════════════════════════════════════════════════════════════

class PreOrder(Base):
    """Pre-orders for upcoming products"""
    __tablename__ = "pre_orders"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    product_id = Column(String, ForeignKey("products.id"), nullable=False, index=True)
    customer_id = Column(String, ForeignKey("customers.id"), nullable=False, index=True)
    
    quantity = Column(Integer, default=1)
    expected_availability_date = Column(Date)
    
    # Payment
    deposit_amount = Column(Numeric(10, 2))  # Upfront payment
    deposit_paid = Column(Boolean, default=False)
    
    status = Column(String(50))  # pending, confirmed, fulfilled, cancelled
    
    created_at = Column(DateTime, default=datetime.utcnow)
    fulfilled_at = Column(DateTime)


class StockAlert(Base):
    """Back-in-stock notifications"""
    __tablename__ = "stock_alerts"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    product_id = Column(String, ForeignKey("products.id"), nullable=False, index=True)
    variant_id = Column(String, ForeignKey("product_variants.id"))
    customer_id = Column(String, ForeignKey("customers.id"), index=True)
    
    email = Column(String(255))
    phone = Column(String(20))
    
    is_notified = Column(Boolean, default=False)
    notified_at = Column(DateTime)
    
    created_at = Column(DateTime, default=datetime.utcnow)


# ═══════════════════════════════════════════════════════════════
# AFFILIATE & REFERRAL PROGRAM
# ═══════════════════════════════════════════════════════════════

class Affiliate(Base):
    """Affiliate partners"""
    __tablename__ = "affiliates"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    organization_id = Column(String, ForeignKey("organizations.id"), index=True)
    user_id = Column(String, ForeignKey("users.id"), unique=True)
    
    affiliate_code = Column(String(100), unique=True, index=True)
    
    # Commission
    commission_rate = Column(Float, default=10.0)  # Percentage
    commission_type = Column(String(50))  # percentage, fixed
    
    # Stats
    total_sales = Column(Numeric(15, 2), default=0)
    total_commission = Column(Numeric(15, 2), default=0)
    total_referrals = Column(Integer, default=0)
    
    # Payout
    bank_account = Column(String(100))
    paypal_email = Column(String(255))
    
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)


class AffiliateClick(Base):
    """Affiliate link clicks"""
    __tablename__ = "affiliate_clicks"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    affiliate_id = Column(String, ForeignKey("affiliates.id"), index=True)
    
    ip_address = Column(String(50))
    user_agent = Column(String(500))
    referrer = Column(String(500))
    
    # Conversion
    converted = Column(Boolean, default=False)
    order_id = Column(String, ForeignKey("orders.id"))
    
    created_at = Column(DateTime, default=datetime.utcnow, index=True)


class AffiliateCommission(Base):
    """Affiliate commissions"""
    __tablename__ = "affiliate_commissions"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    affiliate_id = Column(String, ForeignKey("affiliates.id"), nullable=False, index=True)
    order_id = Column(String, ForeignKey("orders.id"), nullable=False, index=True)
    
    order_amount = Column(Numeric(15, 2))
    commission_rate = Column(Float)
    commission_amount = Column(Numeric(10, 2), nullable=False)
    
    status = Column(String(50))  # pending, approved, paid
    paid_at = Column(DateTime)
    
    created_at = Column(DateTime, default=datetime.utcnow)


# ═══════════════════════════════════════════════════════════════
# SOCIAL COMMERCE
# ═══════════════════════════════════════════════════════════════

class SocialPost(Base):
    """Social media posts with shoppable products"""
    __tablename__ = "social_posts"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    organization_id = Column(String, ForeignKey("organizations.id"), index=True)
    
    platform = Column(String(50))  # instagram, facebook, tiktok, youtube
    platform_post_id = Column(String(255))
    
    content = Column(Text)
    media_urls = Column(JSON)
    
    tagged_products = Column(JSON)  # List of product IDs
    
    # Stats
    likes_count = Column(Integer, default=0)
    comments_count = Column(Integer, default=0)
    shares_count = Column(Integer, default=0)
    views_count = Column(Integer, default=0)
    
    # Conversions
    clicks = Column(Integer, default=0)
    orders = Column(Integer, default=0)
    revenue = Column(Numeric(15, 2), default=0)
    
    posted_at = Column(DateTime)
    created_at = Column(DateTime, default=datetime.utcnow)


# ═══════════════════════════════════════════════════════════════
# LIVE SHOPPING & STREAMS
# ═══════════════════════════════════════════════════════════════

class LiveStream(Base):
    """Live shopping streams"""
    __tablename__ = "live_streams"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    organization_id = Column(String, ForeignKey("organizations.id"), index=True)
    host_id = Column(String, ForeignKey("users.id"))
    
    title = Column(String(500))
    description = Column(Text)
    
    # Stream
    stream_url = Column(String(500))
    stream_key = Column(String(255))
    
    # Products
    featured_products = Column(JSON)  # Product IDs
    
    # Schedule
    scheduled_start = Column(DateTime)
    actual_start = Column(DateTime)
    ended_at = Column(DateTime)
    
    # Stats
    peak_viewers = Column(Integer, default=0)
    total_views = Column(Integer, default=0)
    total_messages = Column(Integer, default=0)
    total_orders = Column(Integer, default=0)
    total_revenue = Column(Numeric(15, 2), default=0)
    
    status = Column(String(50))  # scheduled, live, ended, cancelled
    
    created_at = Column(DateTime, default=datetime.utcnow)


# ═══════════════════════════════════════════════════════════════
# CUSTOMER SUPPORT & LIVE CHAT
# ═══════════════════════════════════════════════════════════════

class SupportTicket(Base):
    """Customer support tickets"""
    __tablename__ = "support_tickets"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    organization_id = Column(String, ForeignKey("organizations.id"), index=True)
    customer_id = Column(String, ForeignKey("customers.id"), index=True)
    order_id = Column(String, ForeignKey("orders.id"))
    
    ticket_number = Column(String(50), unique=True, index=True)
    
    # Content
    subject = Column(String(500))
    description = Column(Text)
    category = Column(String(100))  # order_issue, product_question, refund, technical
    priority = Column(String(50))  # low, medium, high, urgent
    
    # Assignment
    assigned_to = Column(String, ForeignKey("users.id"))
    
    # Status
    status = Column(String(50), index=True)  # open, in_progress, waiting, resolved, closed
    
    # Satisfaction
    rating = Column(Integer)  # 1-5
    feedback = Column(Text)
    
    created_at = Column(DateTime, default=datetime.utcnow, index=True)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    resolved_at = Column(DateTime)
    closed_at = Column(DateTime)


class TicketMessage(Base):
    """Support ticket messages"""
    __tablename__ = "ticket_messages"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    ticket_id = Column(String, ForeignKey("support_tickets.id"), nullable=False, index=True)
    user_id = Column(String, ForeignKey("users.id"))
    
    message = Column(Text, nullable=False)
    attachments = Column(JSON)  # File URLs
    
    is_internal = Column(Boolean, default=False)  # Internal note vs customer-facing
    is_automated = Column(Boolean, default=False)
    
    created_at = Column(DateTime, default=datetime.utcnow)


# ═══════════════════════════════════════════════════════════════
# FRAUD DETECTION & SECURITY
# ═══════════════════════════════════════════════════════════════

class FraudCheck(Base):
    """Fraud detection checks"""
    __tablename__ = "fraud_checks"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    order_id = Column(String, ForeignKey("orders.id"), unique=True, index=True)
    
    risk_score = Column(Integer)  # 0-100
    risk_level = Column(String(50))  # low, medium, high
    
    # Checks
    checks_performed = Column(JSON)
    flags_raised = Column(JSON)
    
    # Decision
    decision = Column(String(50))  # approved, manual_review, rejected
    reviewed_by = Column(String, ForeignKey("users.id"))
    review_notes = Column(Text)
    
    created_at = Column(DateTime, default=datetime.utcnow)
    reviewed_at = Column(DateTime)


# ═══════════════════════════════════════════════════════════════
# A/B TESTING
# ═══════════════════════════════════════════════════════════════

class ABTest(Base):
    """A/B testing experiments"""
    __tablename__ = "ab_tests"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    organization_id = Column(String, ForeignKey("organizations.id"), index=True)
    
    name = Column(String(255), nullable=False)
    description = Column(Text)
    
    # Variants (JSON)
    variants = Column(JSON)  # [{"name": "A", "traffic": 50}, {"name": "B", "traffic": 50}]
    
    # Target
    target_url = Column(String(500))
    target_audience = Column(JSON)  # Criteria
    
    # Metrics
    goal_metric = Column(String(100))  # conversion_rate, revenue, clicks
    
    # Status
    status = Column(String(50))  # draft, running, paused, completed
    
    starts_at = Column(DateTime)
    ends_at = Column(DateTime)
    
    created_at = Column(DateTime, default=datetime.utcnow)


class ABTestAssignment(Base):
    """User variant assignments"""
    __tablename__ = "ab_test_assignments"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    test_id = Column(String, ForeignKey("ab_tests.id"), index=True)
    customer_id = Column(String, ForeignKey("customers.id"), index=True)
    
    variant = Column(String(50))
    
    # Conversion
    converted = Column(Boolean, default=False)
    conversion_value = Column(Numeric(10, 2))
    
    assigned_at = Column(DateTime, default=datetime.utcnow)
    converted_at = Column(DateTime)


# ═══════════════════════════════════════════════════════════════
# ADVANCED ANALYTICS
# ═══════════════════════════════════════════════════════════════

class ProductView(Base):
    """Product view tracking (for recommendations)"""
    __tablename__ = "product_views"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    product_id = Column(String, ForeignKey("products.id"), nullable=False, index=True)
    customer_id = Column(String, ForeignKey("customers.id"), index=True)
    session_id = Column(String(255), index=True)
    
    # Context
    source = Column(String(100))  # search, category, recommendation, direct
    referrer = Column(String(500))
    
    # Device
    device_type = Column(String(50))  # mobile, tablet, desktop
    browser = Column(String(100))
    os = Column(String(100))
    
    # Location
    country = Column(String(2))
    city = Column(String(100))
    
    # Duration
    duration_seconds = Column(Integer)
    
    viewed_at = Column(DateTime, default=datetime.utcnow, index=True)
    
    __table_args__ = (
        Index('idx_product_view_product_date', 'product_id', 'viewed_at'),
        Index('idx_product_view_customer_date', 'customer_id', 'viewed_at'),
    )


class SearchQuery(Base):
    """Search query tracking"""
    __tablename__ = "search_queries"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    organization_id = Column(String, ForeignKey("organizations.id"), index=True)
    customer_id = Column(String, ForeignKey("customers.id"))
    
    query = Column(String(500), nullable=False, index=True)
    results_count = Column(Integer)
    
    # Clicked result
    clicked_product_id = Column(String, ForeignKey("products.id"))
    click_position = Column(Integer)
    
    # Conversion
    resulted_in_purchase = Column(Boolean, default=False)
    order_id = Column(String, ForeignKey("orders.id"))
    
    created_at = Column(DateTime, default=datetime.utcnow, index=True)


# ═══════════════════════════════════════════════════════════════
# PRICE TRACKING & ALERTS
# ═══════════════════════════════════════════════════════════════

class PriceHistory(Base):
    """Product price history"""
    __tablename__ = "price_history"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    product_id = Column(String, ForeignKey("products.id"), nullable=False, index=True)
    
    old_price = Column(Numeric(10, 2))
    new_price = Column(Numeric(10, 2), nullable=False)
    
    change_percentage = Column(Float)
    reason = Column(String(255))  # campaign, competitor, seasonal
    
    changed_at = Column(DateTime, default=datetime.utcnow, index=True)


class PriceAlert(Base):
    """Customer price drop alerts"""
    __tablename__ = "price_alerts"
    
    id = Column(String, primary_key=True, default=generate_uuid)
    customer_id = Column(String, ForeignKey("customers.id"), nullable=False, index=True)
    product_id = Column(String, ForeignKey("products.id"), nullable=False, index=True)
    
    target_price = Column(Numeric(10, 2), nullable=False)
    
    is_notified = Column(Boolean, default=False)
    notified_at = Column(DateTime)
    
    created_at = Column(DateTime, default=datetime.utcnow)
