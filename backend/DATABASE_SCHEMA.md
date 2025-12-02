# 🏆 Enterprise Super App Database Schema

**A101.com / Amazon / Trendyol Seviyesi - Tam E-commerce Altyapısı**

---

## 📊 Database Özeti

### Toplam İstatistikler
- ✅ **40+ Tablo**
- ✅ **Multi-Tenant** (Organization bazlı izolasyon)
- ✅ **Marketplace** ready (Vendor/Supplier desteği)
- ✅ **Full E-commerce** (Sepet, Sipariş, Ödeme, Kargo, İade)
- ✅ **Marketing** (Kampanyalar, İndirim kodları, Flash sale)
- ✅ **Communications** (Email/SMS templates & logging)
- ✅ **Analytics** (Günlük snapshot'lar)
- ✅ **Audit Trail** (Tüm değişiklikler loglanır)

---

## 🏗️ Database Architecture

```
┌────────────────────────────────────────────────────────────────┐
│                    MULTI-TENANT LAYER                           │
│  Organizations → Branches → Users → Vendors                    │
└─────────────────────┬──────────────────────────────────────────┘
                      │
      ┌───────────────┼───────────────────────────────┐
      │               │                               │
      ▼               ▼                               ▼
┌─────────────┐ ┌─────────────┐              ┌──────────────┐
│  PRODUCTS   │ │   ORDERS    │              │  CUSTOMERS   │
│  CATALOG    │ │   SALES     │              │  LOYALTY     │
└──────┬──────┘ └──────┬──────┘              └──────┬───────┘
       │               │                             │
       │               │        ┌────────────────────┘
       │               │        │
       ▼               ▼        ▼
┌─────────────────────────────────────────────────────────┐
│              SUPPORTING SYSTEMS                          │
│  Inventory│Shipping│Payments│Returns│Marketing│Analytics│
└──────────────────────────────────────────────────────────┘
```

---

## 📋 Tablo Grupları

### 1. 🏢 MULTI-TENANCY & ORGANIZATION (3 tablo)
```
organizations          # Firmalar/İşletmeler
├── branches           # Şubeler/Mağazalar
└── users              # Kullanıcılar (RBAC)
```

**Özellikler:**
- Organization bazlı veri izolasyonu
- Subscription planları (FREE, STARTER, BUSINESS, ENTERPRISE)
- Şube limitleri, kullanıcı limitleri
- Her organization kendi ecosystem'inde çalışır

**Example:**
```python
# Küçük işletme
org_1 = Organization(
    name="Mehmet Market",
    plan="STARTER",
    max_branches=1,
    max_users=5
)

# Büyük zincir
org_2 = Organization(
    name="SuperMarket Chain",
    plan="ENTERPRISE",
    max_branches=100,
    max_users=1000
)
```

---

### 2. 🏪 VENDORS & MARKETPLACE (2 tablo)
```
vendors                # Satıcılar/Tedarikçiler
└── products           # (vendor_id ile link)
```

**Özellikler:**
- Marketplace modeli (A101 Marketplace gibi)
- Vendor onboarding workflow (pending → approved)
- Komisyon sistemi (%)
- Vendor ratings & sales tracking
- Banking bilgileri (IBAN, Hesap No)

**Use Cases:**
- ✅ Kendi ürünleriniz (vendor_id = NULL)
- ✅ Vendor ürünleri (vendor_id = valid)
- ✅ Komisyon hesaplama
- ✅ Vendor ödemeleri

---

### 3. 📦 PRODUCT CATALOG (6 tablo)
```
products               # Ana ürünler
├── product_variants   # Varyantlar (renk, beden, etc.)
├── product_images     # Ürün görselleri
├── categories         # Kategoriler (hiyerarşik)
├── brands             # Markalar
└── vendors            # Satıcılar
```

**Özellikler:**
- ✅ Unlimited variants (Small/Medium/Large, Red/Blue/Green)
- ✅ Multiple images per product
- ✅ Hierarchical categories (Electronics → Phones → iPhones)
- ✅ SEO fields (title, description, keywords)
- ✅ Pricing: base_price, sale_price, cost_price
- ✅ Inventory tracking
- ✅ Stats: views, sales, rating

**Example Product:**
```python
# iPhone 15 Pro
product = Product(
    name="iPhone 15 Pro Max 256GB",
    category="Smartphones",
    brand="Apple",
    base_price=45999.00,
    sale_price=42999.00,  # İndirimli
    variants=[
        {name: "Siyah - 256GB", stock: 10},
        {name: "Mavi - 256GB", stock: 5},
    ],
    images=["url1", "url2", "url3"]
)
```

---

### 4. 📦 INVENTORY & WAREHOUSES (3 tablo)
```
warehouses             # Depolar
├── stock_movements    # Stok hareketleri
└── products           # (stock_quantity)
```

**Movement Types:**
- PURCHASE (Alım)
- SALE (Satış)
- RETURN (İade)
- ADJUSTMENT (Düzeltme)
- TRANSFER (Depo transferi)
- DAMAGE (Hasar)
- LOSS (Kayıp/çalıntı)

**Use Cases:**
- ✅ Multi-warehouse management
- ✅ Stock transfer between warehouses
- ✅ Historical stock tracking
- ✅ Inventory audit trail

---

### 5. 👥 CUSTOMERS (3 tablo)
```
customers              # Müşteriler
├── customer_addresses # Adresler (shipping/billing)
└── loyalty system     # Sadakat puanları
```

**Özellikler:**
- ✅ Customer segments (VIP, Regular, New, Inactive)
- ✅ Loyalty points system
- ✅ Lifetime value tracking
- ✅ Multiple addresses
- ✅ Credit limit & balance
- ✅ Marketing preferences (email/SMS opt-in)

**Segmentation:**
```
VIP:      10+ orders, 50000+ TL spent
Regular:  3+ orders
New:      < 3 orders
Inactive: No order in 6 months
```

---

### 6. 🛒 ORDERS (3 tablo)
```
orders                 # Siparişler
├── order_items        # Sipariş kalemleri
└── order_status_history  # Durum değişiklikleri
```

**Order Statuses:**
```
PENDING → CONFIRMED → PROCESSING → SHIPPED → DELIVERED
                                  ↓
                              CANCELLED / RETURNED / REFUNDED
```

**Özellikler:**
- ✅ Multi-channel (web, mobile, POS, marketplace)
- ✅ Address snapshot (değişse bile geçmiş siparişler korunur)
- ✅ Discount tracking
- ✅ Tax calculation
- ✅ Shipping cost
- ✅ Full audit trail (order_status_history)

---

### 7. 💳 PAYMENTS (3 tablo)
```
payments               # Ödemeler
├── refunds            # İadeler
└── orders             # (payment_status)
```

**Payment Methods:**
- CASH (Nakit)
- CREDIT_CARD (Kredi kartı)
- DEBIT_CARD (Banka kartı)
- BANK_TRANSFER (Havale)
- WALLET (Dijital cüzdan)
- CREDIT (Veresiye)
- INSTALLMENT (Taksit)
- CRYPTO (Kripto para)

**Özellikler:**
- ✅ Multiple payment providers (Stripe, PayPal, Iyzico)
- ✅ Installment support (taksit)
- ✅ Card info (masked)
- ✅ Full refund tracking
- ✅ Payment webhooks ready

---

### 8. 🚚 SHIPPING & LOGISTICS (4 tablo)
```
shipping_providers     # Kargo firmaları (Yurtiçi, Aras, MNG)
├── shipping_rates     # Tarife tablosu
├── shipments          # Gönderiler
└── shipment_tracking  # Takip kayıtları
```

**Providers Integration:**
- Yurtiçi Kargo
- Aras Kargo
- MNG Kargo
- UPS
- DHL
- Custom providers

**Özellikler:**
- ✅ API integration ready
- ✅ Tracking URL templates
- ✅ Weight-based pricing
- ✅ Region-based pricing
- ✅ Estimated delivery time
- ✅ Real-time tracking events

---

### 9. ↩️ RETURNS & REFUNDS (2 tablo)
```
return_requests        # İade talepleri
└── refunds            # İade ödemeleri
```

**Return Reasons:**
- DEFECTIVE (Arızalı)
- WRONG_ITEM (Yanlış ürün)
- NOT_AS_DESCRIBED (Açıklamaya uymuyor)
- CHANGED_MIND (Vazgeçtim)
- DAMAGED (Hasarlı)
- OTHER (Diğer)

**Workflow:**
```
Customer Request → Pending → Approved/Rejected → Completed
```

---

### 10. 🎯 MARKETING & CAMPAIGNS (3 tablo)
```
campaigns              # Kampanyalar
├── discount_codes     # İndirim kodları
└── code_usage         # Kullanım takibi
```

**Campaign Types:**
- PERCENTAGE_DISCOUNT (% indirim)
- FIXED_DISCOUNT (Sabit tutar)
- BUY_X_GET_Y (X al Y öde)
- FREE_SHIPPING (Ücretsiz kargo)
- FLASH_SALE (Flaş indirim)
- BUNDLE (Paket)

**Example:**
```python
# Black Friday Campaign
campaign = Campaign(
    name="Black Friday 2025",
    type="PERCENTAGE_DISCOUNT",
    discount_percentage=50,
    starts_at="2025-11-29 00:00",
    ends_at="2025-11-29 23:59",
    min_purchase_amount=500
)

# Coupon Code
code = DiscountCode(
    code="WELCOME20",
    discount_type="percentage",
    discount_value=20,
    usage_limit_per_customer=1,
    expires_at="2025-12-31"
)
```

---

### 11. 📧 COMMUNICATIONS (2 tablo)
```
notification_templates # Email/SMS şablonları
└── notification_logs  # Gönderim logları
```

**Templates:**
- order_confirmed
- shipping_update
- delivery_notification
- return_approved
- refund_processed
- low_stock_alert
- campaign_notification

**Providers:**
- Email: SendGrid, AWS SES, Mailgun
- SMS: Twilio, Nexmo, Netgsm

**Özellikler:**
- ✅ Dynamic variables ({customer_name}, {order_number})
- ✅ HTML + Text email
- ✅ Delivery tracking (opened, clicked)
- ✅ Failed delivery handling

---

### 12. ⭐ REVIEWS & RATINGS (2 tablo)
```
product_reviews        # Ürün yorumları
└── vendor_reviews     # Satıcı yorumları
```

**Features:**
- ✅ 1-5 star rating
- ✅ Text review + images
- ✅ Verified purchase badge
- ✅ Helpful/not helpful votes
- ✅ Moderation (approval required)
- ✅ Featured reviews

---

### 13. 📊 ANALYTICS (1 tablo)
```
analytics_snapshots    # Günlük analitik snapshot'lar
```

**Daily Metrics:**
- Total orders & revenue
- Profit margin
- Average order value
- New vs returning customers
- Top selling products
- Payment method breakdown
- Refund amount

**Benefits:**
- ⚡ Fast reporting (pre-calculated)
- 📈 Trend analysis
- 🎯 Business insights

---

### 14. 🔐 SYSTEM & AUDIT (2 tablo)
```
audit_logs             # Tüm değişiklikler
└── system_settings    # Sistem ayarları
```

**Audit Logging:**
- Who did what, when
- Before/after values
- IP address & user agent
- Full compliance ready

---

## 🎯 Scalability Features

### 1. Multi-Tenancy
```sql
-- Her sorgu organization_id ile filtrelenir
SELECT * FROM products WHERE organization_id = '{org_id}';

-- Index optimization
CREATE INDEX idx_product_org ON products(organization_id, is_active);
```

### 2. Partitioning Ready
```python
# Büyük tablolar tarih bazlı partition edilebilir
orders:          partition by month
analytics:       partition by month
audit_logs:      partition by month
notifications:   partition by month
```

### 3. Caching Strategy
```python
# Redis caching için
- Product catalog: 1 hour TTL
- Categories: 6 hours TTL
- Campaigns: 30 min TTL
- Analytics: 5 min TTL
```

### 4. Database Indexes
```python
# Critical indexes (already defined)
✅ All foreign keys
✅ organization_id (multi-tenancy)
✅ Created_at (time-series data)
✅ Status fields (filtering)
✅ Composite indexes (multi-column queries)
```

---

## 📈 Performance Benchmarks

### Expected Performance (PostgreSQL)
- Product search: < 50ms
- Order creation: < 100ms
- Analytics query: < 200ms (cached snapshots)
- Bulk operations: Batch processing

### Scalability Targets
| Organization Size | Orders/Day | Products | Users |
|-------------------|------------|----------|-------|
| **Small**         | < 100      | < 1,000  | < 10  |
| **Medium**        | 100-1,000  | 1K-10K   | 10-50 |
| **Large**         | 1K-10K     | 10K-100K | 50-500|
| **Enterprise**    | 10K+       | 100K+    | 500+  |

---

## 🚀 Migration Strategy

### Initial Setup
```bash
# Auto-create all tables
python -c "from app.models.database import create_all_tables; import asyncio; asyncio.run(create_all_tables())"
```

### Alembic Migrations
```bash
# Generate migration
alembic revision --autogenerate -m "Add new feature"

# Apply
alembic upgrade head

# Rollback
alembic downgrade -1
```

---

## 💡 Use Case Examples

### Example 1: Small Local Store
```python
org = Organization(plan="STARTER", max_branches=1)
branch = Branch(name="Ana Mağaza")
products = 500  # own products
orders = 50/day
```

### Example 2: Marketplace (A101 style)
```python
org = Organization(plan="ENTERPRISE", max_branches=100)
vendors = 50  # 3rd party sellers
products = 10,000  # mixed (own + vendor)
campaigns = 20  # active campaigns
orders = 5,000/day
```

### Example 3: E-commerce Giant
```python
org = Organization(plan="UNLIMITED")
branches = 100
warehouses = 10
vendors = 500
products = 100,000+
campaigns = 100
discount_codes = 1,000+
orders = 50,000/day
emails = 100,000/day
```

---

## ✅ ÖZET

**Bu database schema ile:**

✅ Küçük işletmeden büyük marketplace'e ölçeklenebilir  
✅ Multi-tenant (sınırsız firma)  
✅ Vendor/Marketplace desteği  
✅ Full e-commerce (Sepet → Ödeme → Kargo → İade)  
✅ Marketing & kampanyalar  
✅ Email/SMS altyapısı  
✅ Analytics & raporlama  
✅ Audit trail & compliance  
✅ A101.com / Amazon seviyesi  

**40+ tablo ile production-ready enterprise altyapı!** 🏆
