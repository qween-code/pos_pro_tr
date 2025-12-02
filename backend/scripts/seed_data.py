"""
Seed Initial Data
Populates database with demo data for testing
"""

import asyncio
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from decimal import Decimal

from app.core.config import settings
from app.core.security import get_password_hash
from app.models.database import Organization, Branch, User, Category, Product

async def seed_data():
    """Seed initial data"""
    engine = create_async_engine(settings.DATABASE_URL)
    AsyncSessionLocal = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    async with AsyncSessionLocal() as db:
        print("🌱 Seeding initial data...")
        
        # 1. Create Organization
        org = Organization(
            name="Demo Market",
            slug="demo-market",
            email="demo@pospro.com",
            phone="+90 555 123 4567",
            plan="business",
            max_branches=10,
            max_users=50,
            is_active=True
        )
        db.add(org)
        await db.flush()
        print(f"✅ Organization created: {org.name}")
        
        # 2. Create Branch
        branch = Branch(
            organization_id=org.id,
            name="Ana Şube",
            code="BRANCH001",
            phone="+90 555 111 2222",
            address="İstanbul, Türkiye",
            is_active=True
        )
        db.add(branch)
        await db.flush()
        print(f"✅ Branch created: {branch.name}")
        
        # 3. Create Users
        admin = User(
            organization_id=org.id,
            email="admin@pospro.com",
            hashed_password=get_password_hash("admin123"),
            first_name="Admin",
            last_name="User",
            role="org_admin",
            is_active=True,
            is_verified=True
        )
        db.add(admin)
        
        cashier = User(
            organization_id=org.id,
            email="cashier@pospro.com",
            hashed_password=get_password_hash("cashier123"),
            first_name="Cashier",
            last_name="User",
            role="cashier",
            is_active=True
        )
        db.add(cashier)
        await db.flush()
        print(f"✅ Users created: Admin, Cashier")
        
        # 4. Create Categories
        categories = [
            Category(organization_id=org.id, name="Elektronik", slug="elektronik", is_active=True),
            Category(organization_id=org.id, name="Giyim", slug="giyim", is_active=True),
            Category(organization_id=org.id, name="Gıda", slug="gida", is_active=True),
            Category(organization_id=org.id, name="Ev & Yaşam", slug="ev-yasam", is_active=True),
            Category(organization_id=org.id, name="Kozmetik", slug="kozmetik", is_active=True),
        ]
        for cat in categories:
            db.add(cat)
        await db.flush()
        print(f"✅ Categories created: {len(categories)}")
        
        # 5. Create Sample Products
        products = [
            Product(
                organization_id=org.id,
                category_id=categories[0].id,
                name="iPhone 15 Pro",
                sku="IPH15PRO",
                barcode="1234567890123",
                base_price=Decimal("45999.00"),
                cost_price=Decimal("38000.00"),
                stock_quantity=10,
                is_active=True
            ),
            Product(
                organization_id=org.id,
                category_id=categories[1].id,
                name="Erkek T-Shirt",
                sku="TSHIRT001",
                barcode="2345678901234",
                base_price=Decimal("199.90"),
                cost_price=Decimal("120.00"),
                stock_quantity=50,
                is_active=True
            ),
            Product(
                organization_id=org.id,
                category_id=categories[2].id,
                name="Organik Zeytinyağı 1L",
                sku="OIL001",
                barcode="3456789012345",
                base_price=Decimal("89.90"),
                cost_price=Decimal("55.00"),
                stock_quantity=30,
                is_active=True
            ),
        ]
        for product in products:
            db.add(product)
        await db.flush()
        print(f"✅ Products created: {len(products)}")
        
        # 6. Create Sample Customers
        from app.models.database import Customer
        customers = [
            Customer(
                organization_id=org.id,
                first_name="Ahmet",
                last_name="Yılmaz",
                email="ahmet.yilmaz@example.com",
                phone="+90 555 111 2222",
                is_active=True
            ),
            Customer(
                organization_id=org.id,
                first_name="Ayşe",
                last_name="Demir",
                email="ayse.demir@example.com",
                phone="+90 555 222 3333",
                is_active=True
            ),
            Customer(
                organization_id=org.id,
                first_name="Mehmet",
                last_name="Kaya",
                email="mehmet.kaya@example.com",
                phone="+90 555 333 4444",
                is_active=True
            ),
        ]
        for customer in customers:
            db.add(customer)
        await db.flush()
        print(f"✅ Customers created: {len(customers)}")
        
        await db.commit()
        print("\n✨ Seeding completed successfully!")
        print("\n🔑 Default Credentials:")
        print("   Admin:   admin@pospro.com / admin123")
        print("   Cashier: cashier@pospro.com / cashier123")
    
    await engine.dispose()

if __name__ == "__main__":
    asyncio.run(seed_data())
