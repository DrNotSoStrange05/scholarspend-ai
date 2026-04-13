"""
POST /users/     — Register a new user.
GET  /users/{id} — Fetch user profile.
PUT  /users/{id} — Update user profile / balance.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from passlib.context import CryptContext
from sqlalchemy.ext.asyncio import AsyncSession

from app import crud, schemas
from app.database import get_db

router = APIRouter()
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


@router.post(
    "/",
    response_model=schemas.UserResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Register a new student user",
)
async def create_user(
    payload: schemas.UserCreate,
    db: AsyncSession = Depends(get_db),
):
    existing = await crud.get_user_by_email(db, payload.email)
    if existing:
        raise HTTPException(status_code=409, detail="Email already registered")

    hashed = pwd_context.hash(payload.password)
    user = await crud.create_user(db, payload, hashed)
    return user


@router.get(
    "/{user_id}",
    response_model=schemas.UserWithStats,
    summary="Get user profile with basic survival stats",
)
async def get_user(user_id: int, db: AsyncSession = Depends(get_db)):
    user = await crud.get_user(db, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user


@router.put(
    "/{user_id}",
    response_model=schemas.UserResponse,
    summary="Update user profile or balance",
)
async def update_user(
    user_id: int,
    payload: schemas.UserUpdate,
    db: AsyncSession = Depends(get_db),
):
    user = await crud.get_user(db, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(user, field, value)
    await db.commit()
    await db.refresh(user)
    return user
