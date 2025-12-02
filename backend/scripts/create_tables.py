"""
Database Migration Script
Creates all 70+ tables with indexes
"""

import asyncio
from sqlalchemy.ext.asyncio import create_async_engine
from app.models.database import Base
from app.models.global_features import *  # Import global models
from app.core.config import settings

async def create_all_tables():
    """Create all database tables"""
    engine = create_async_engine(
        settings.DATABASE_URL,
        echo=True
    )
    
    async with engine.begin() as conn:
        # Drop all tables (development only!)
        # await conn.run_sync(Base.metadata.drop_all)
        
        # Create all tables
        await conn.run_sync(Base.metadata.create_all)
    
    await engine.dispose()
    
    print("✅ All database tables created successfully!")
    print(f"📊 Total tables: {len(Base.metadata.tables)}")
    print("\nCreated tables:")
    for table_name in sorted(Base.metadata.tables.keys()):
        print(f"  ✓ {table_name}")

if __name__ == "__main__":
    print("🚀 Creating database tables...")
    asyncio.run(create_all_tables())
