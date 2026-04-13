"""
POST   /subscriptions/         — Add a recurring subscription.
GET    /subscriptions/         — List active subscriptions.
PUT    /subscriptions/{sub_id} — Update a subscription.
DELETE /subscriptions/{sub_id} — Remove a subscription.
"""

from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app import crud, schemas
from app.database import get_db

router = APIRouter()


@router.post(
    "/",
    response_model=schemas.SubscriptionResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Add a recurring subscription (e.g. Netflix, Spotify)",
)
async def add_subscription(
    user_id: int,
    payload: schemas.SubscriptionCreate,
    db: AsyncSession = Depends(get_db),
):
    user = await crud.get_user(db, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return await crud.create_subscription(db, user_id, payload)


@router.get(
    "/",
    response_model=List[schemas.SubscriptionResponse],
    summary="List active subscriptions for a user",
)
async def list_subscriptions(
    user_id: int,
    active_only: bool = True,
    db: AsyncSession = Depends(get_db),
):
    user = await crud.get_user(db, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return await crud.get_subscriptions(db, user_id, active_only=active_only)


@router.put(
    "/{sub_id}",
    response_model=schemas.SubscriptionResponse,
    summary="Update a subscription",
)
async def update_subscription(
    sub_id: int,
    payload: schemas.SubscriptionUpdate,
    db: AsyncSession = Depends(get_db),
):
    from sqlalchemy import select
    from app.models import Subscription

    result = await db.execute(select(Subscription).where(Subscription.id == sub_id))
    sub = result.scalar_one_or_none()
    if not sub:
        raise HTTPException(status_code=404, detail="Subscription not found")
    return await crud.update_subscription(db, sub, payload)


@router.delete(
    "/{sub_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete a subscription",
)
async def delete_subscription(
    sub_id: int,
    db: AsyncSession = Depends(get_db),
):
    from sqlalchemy import select
    from app.models import Subscription

    result = await db.execute(select(Subscription).where(Subscription.id == sub_id))
    sub = result.scalar_one_or_none()
    if not sub:
        raise HTTPException(status_code=404, detail="Subscription not found")
    await crud.delete_subscription(db, sub)
