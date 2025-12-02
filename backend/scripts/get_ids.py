import asyncio
import sys
import os

# Add parent directory to path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.db.session import async_session
from app.models.database import Branch, Product
from sqlalchemy import select

async def get_ids():
    async with async_session() as db:
        # Get Branch
        result = await db.execute(select(Branch))
        branch = result.scalars().first()
        print(f"BRANCH_ID={branch.id if branch else 'None'}")
        
        # Get Product
        result = await db.execute(select(Product))
        product = result.scalars().first()
        print(f"PRODUCT_ID={product.id if product else 'None'}")

if __name__ == "__main__":
    if sys.platform == "win32":
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    asyncio.run(get_ids())
