"""
🔐 Authentication API Endpoints
"""

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from datetime import datetime, timedelta

from app.db.session import get_db
from app.models.database import User
from app.schemas.schemas import UserRegister, UserLogin, Token, UserResponse
from app.core.security import (
    verify_password, get_password_hash,
    create_access_token, create_refresh_token, verify_token
)
from app.core.config import settings

router = APIRouter(prefix="/auth", tags=["Authentication"])
security = HTTPBearer()


@router.post("/register", response_model=UserResponse, status_code=201)
async def register(
    user_data: UserRegister,
    db: AsyncSession = Depends(get_db)
):
    """
    👤 REGISTER NEW USER
    
    Creates new cashier/staff account
    """
    # Check if email exists
    existing = await db.execute(
        select(User).where(User.email == user_data.email)
    )
    if existing.scalar_one_or_none():
        raise HTTPException(
            status_code=400,
            detail="Email already registered"
        )
    
    # Create user
    new_user = User(
        email=user_data.email,
        hashed_password=get_password_hash(user_data.password),
        first_name=user_data.first_name,
        last_name=user_data.last_name,
        phone=user_data.phone,
        organization_id=user_data.organization_id,
        role="cashier",  # Default role
        is_active=True
    )
    
    db.add(new_user)
    await db.commit()
    await db.refresh(new_user)
    
    return new_user


@router.post("/login", response_model=Token)
async def login(
    credentials: UserLogin,
    db: AsyncSession = Depends(get_db)
):
    """
    🔑 LOGIN
    
    Returns JWT access & refresh tokens
    """
    # Find user
    result = await db.execute(
        select(User).where(User.email == credentials.email)
    )
    user = result.scalar_one_or_none()
    
    if not user or not verify_password(credentials.password, user.hashed_password):
        raise HTTPException(
            status_code=401,
            detail="Incorrect email or password"
        )
    
    if not user.is_active:
        raise HTTPException(
            status_code=403,
            detail="Account is disabled"
        )
    
    # Create tokens
    access_token = create_access_token(
        data={
            "sub": user.id,
            "email": user.email,
            "role": user.role,
            "organization_id": user.organization_id
        }
    )
    
    refresh_token = create_refresh_token(
        data={"sub": user.id}
    )
    
    # Update last login
    user.last_login_at = datetime.utcnow()
    await db.commit()
    
    return Token(
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60
    )


@router.get("/me", response_model=UserResponse)
async def get_current_user(
    db: AsyncSession = Depends(get_db),
    token: HTTPAuthorizationCredentials = Depends(security)
):
    """
    👤 GET CURRENT USER
    
    Returns logged-in user info
    """
    payload = verify_token(token.credentials)
    user_id = payload.get("sub")
    
    result = await db.execute(
        select(User).where(User.id == user_id)
    )
    user = result.scalar_one_or_none()
    
    if not user:
        raise HTTPException(404, "User not found")
    
    return user
