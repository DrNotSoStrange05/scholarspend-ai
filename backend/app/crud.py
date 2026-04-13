"""
ScholarSpend AI — CRUD Helpers
Async database operations for User, Transaction, and Subscription.
"""

from datetime import datetime, timedelta
from typing import List, Optional

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app import models, schemas


# ═══════════════════════════════════════════════════════════════
# USER CRUD
# ═══════════════════════════════════════════════════════════════


async def get_user(db: AsyncSession, user_id: int) -> Optional[models.User]:
    result = await db.execute(select(models.User).where(models.User.id == user_id))
    return result.scalar_one_or_none()


async def get_user_by_email(db: AsyncSession, email: str) -> Optional[models.User]:
    result = await db.execute(select(models.User).where(models.User.email == email))
    return result.scalar_one_or_none()


async def create_user(db: AsyncSession, payload: schemas.UserCreate, hashed_password: str) -> models.User:
    user = models.User(
        email=payload.email,
        hashed_password=hashed_password,
        full_name=payload.full_name,
        phone_number=payload.phone_number,
        current_balance=payload.current_balance,
        currency=payload.currency,
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return user


async def update_user_balance(db: AsyncSession, user: models.User, new_balance: float) -> models.User:
    user.current_balance = new_balance
    await db.commit()
    await db.refresh(user)
    return user


# ═══════════════════════════════════════════════════════════════
# TRANSACTION CRUD
# ═══════════════════════════════════════════════════════════════


async def get_transactions(
    db: AsyncSession,
    user_id: int,
    skip: int = 0,
    limit: int = 50,
) -> List[models.Transaction]:
    result = await db.execute(
        select(models.Transaction)
        .where(models.Transaction.user_id == user_id)
        .order_by(models.Transaction.transacted_at.desc())
        .offset(skip)
        .limit(limit)
    )
    return list(result.scalars().all())


async def get_transaction_by_ref(
    db: AsyncSession, reference_id: str
) -> Optional[models.Transaction]:
    """Deduplication check — prevents re-inserting the same SMS twice."""
    result = await db.execute(
        select(models.Transaction).where(models.Transaction.reference_id == reference_id)
    )
    return result.scalar_one_or_none()


async def create_transaction(
    db: AsyncSession,
    user_id: int,
    payload: schemas.TransactionCreate,
) -> models.Transaction:
    # Dedup guard: skip if reference already exists
    if payload.reference_id:
        existing = await get_transaction_by_ref(db, payload.reference_id)
        if existing:
            return existing

    txn = models.Transaction(
        user_id=user_id,
        amount=payload.amount,
        transaction_type=payload.transaction_type,
        merchant=payload.merchant,
        description=payload.description,
        raw_text=payload.raw_text,
        is_sms_parsed=payload.is_sms_parsed,
        category=payload.category,
        reference_id=payload.reference_id,
        bank_name=payload.bank_name,
        account_last4=payload.account_last4,
        balance_after=payload.balance_after,
        transacted_at=payload.transacted_at or datetime.utcnow(),
    )
    db.add(txn)

    # Update user's running balance for debit/credit
    user = await get_user(db, user_id)
    if user:
        if payload.transaction_type == models.TransactionType.DEBIT:
            user.current_balance -= payload.amount
        else:
            user.current_balance += payload.amount

    await db.commit()
    await db.refresh(txn)
    return txn


async def bulk_create_transactions(
    db: AsyncSession,
    user_id: int,
    payloads: List[schemas.TransactionCreate],
) -> List[models.Transaction]:
    created = []
    for p in payloads:
        txn = await create_transaction(db, user_id, p)
        created.append(txn)
    return created


# ═══════════════════════════════════════════════════════════════
# ANALYTICS HELPERS
# ═══════════════════════════════════════════════════════════════


async def get_daily_spend_last_n_days(
    db: AsyncSession, user_id: int, days: int = 30
) -> List[dict]:
    """
    Returns per-day debit totals for the last `days` days.
    Used by the forecasting engine to compute the rolling avg daily spend.
    """
    since = datetime.utcnow() - timedelta(days=days)
    result = await db.execute(
        select(
            func.date(models.Transaction.transacted_at).label("day"),
            func.sum(models.Transaction.amount).label("total"),
        )
        .where(
            models.Transaction.user_id == user_id,
            models.Transaction.transaction_type == models.TransactionType.DEBIT,
            models.Transaction.transacted_at >= since,
        )
        .group_by(func.date(models.Transaction.transacted_at))
        .order_by(func.date(models.Transaction.transacted_at))
    )
    return [{"day": row.day, "total": float(row.total)} for row in result]


async def get_category_breakdown(
    db: AsyncSession, user_id: int, days: int = 30
) -> List[dict]:
    """Per-category spending totals for the spending breakdown widget."""
    since = datetime.utcnow() - timedelta(days=days)
    result = await db.execute(
        select(
            models.Transaction.category,
            func.sum(models.Transaction.amount).label("total"),
            func.count(models.Transaction.id).label("count"),
        )
        .where(
            models.Transaction.user_id == user_id,
            models.Transaction.transaction_type == models.TransactionType.DEBIT,
            models.Transaction.transacted_at >= since,
        )
        .group_by(models.Transaction.category)
    )
    rows = result.all()
    grand_total = sum(float(r.total) for r in rows) or 1.0
    return [
        {
            "category": r.category,
            "total_spent": float(r.total),
            "transaction_count": int(r.count),
            "percentage_of_total": round(float(r.total) / grand_total * 100, 2),
        }
        for r in rows
    ]


# ═══════════════════════════════════════════════════════════════
# SUBSCRIPTION CRUD
# ═══════════════════════════════════════════════════════════════


async def get_subscriptions(
    db: AsyncSession, user_id: int, active_only: bool = True
) -> List[models.Subscription]:
    stmt = select(models.Subscription).where(models.Subscription.user_id == user_id)
    if active_only:
        stmt = stmt.where(models.Subscription.is_active == True)  # noqa: E712
    result = await db.execute(stmt)
    return list(result.scalars().all())


async def create_subscription(
    db: AsyncSession, user_id: int, payload: schemas.SubscriptionCreate
) -> models.Subscription:
    sub = models.Subscription(
        user_id=user_id,
        name=payload.name,
        amount=payload.amount,
        billing_cycle=payload.billing_cycle,
        category=payload.category,
        next_billing_date=payload.next_billing_date,
        is_active=payload.is_active,
    )
    db.add(sub)
    await db.commit()
    await db.refresh(sub)
    return sub


async def update_subscription(
    db: AsyncSession,
    sub: models.Subscription,
    payload: schemas.SubscriptionUpdate,
) -> models.Subscription:
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(sub, field, value)
    await db.commit()
    await db.refresh(sub)
    return sub


async def delete_subscription(db: AsyncSession, sub: models.Subscription) -> None:
    await db.delete(sub)
    await db.commit()
