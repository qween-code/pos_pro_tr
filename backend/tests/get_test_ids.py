"""
Quick script to get branch and product IDs from database
"""
import asyncio
import sys
import os

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy import select
from app.db.session import async_session
from app.models.database import Branch, Product

async def get_ids():
    async with async_session() as db:
        # Get first branch
        branch_result = await db.execute(select(Branch).limit(1))
        branch = branch_result.scalars().first()
        
        # Get first product
        product_result = await db.execute(select(Product).limit(1))
        product = product_result.scalars().first()
        
        if branch and product:
            print(f"BRANCH_ID={branch.id}")
            print(f"PRODUCT_ID={product.id}")
            print(f"PRODUCT_PRICE={product.base_price}")
            return branch.id, product.id, product.base_price
        else:
            print("ERROR: No data found")
            return None, None, None

if __name__ == "__main__":
    if sys.platform == "win32":
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    
    asyncio.run(get_ids())
