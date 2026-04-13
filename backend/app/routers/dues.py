"""
ScholarSpend AI — Dues Router
Endpoints: GET /dues  POST /dues  PATCH /dues/{due_id}/pay
"""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app import crud, schemas
from app.database import get_db

router = APIRouter()


@router.get(
    "/",
    response_model=list[schemas.DueResponse],
    summary="List pending dues (debts & credits) for a user",
)
async def list_dues(
    user_id: int,
    include_paid: bool = False,
    db: AsyncSession = Depends(get_db),
):
    """
    Returns dues for the given user.
    By default only unpaid dues are returned; pass `include_paid=true` to see all.
    Each due has `is_owed_to_me`:
      - True  → someone owes ME money (green / income side)
      - False → I owe someone money   (red / expense side)
    """
    user = await crud.get_user(db, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return await crud.get_dues(db, user_id, include_paid=include_paid)


@router.post(
    "/",
    response_model=schemas.DueResponse,
    status_code=201,
    summary="Record a new due (someone owes me / I owe someone)",
)
async def create_due(
    user_id: int,
    payload: schemas.DueCreate,
    db: AsyncSession = Depends(get_db),
):
    user = await crud.get_user(db, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return await crud.create_due(db, user_id, payload)


@router.patch(
    "/{due_id}/pay",
    response_model=schemas.DueResponse,
    summary="Mark a due as paid / settled",
)
async def pay_due(
    due_id: int,
    db: AsyncSession = Depends(get_db),
):
    due = await crud.get_due(db, due_id)
    if not due:
        raise HTTPException(status_code=404, detail="Due not found")
    if due.is_paid:
        raise HTTPException(status_code=400, detail="Due is already marked as paid")
    return await crud.mark_due_paid(db, due)
