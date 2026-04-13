"""
POST /transactions/sync  — Batch-parse incoming SMS and store transactions.
GET  /transactions/      — List paginated transactions for a user.
"""

from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app import crud, schemas
from app.database import get_db
from app.sms_parser import ParsedSMS, parse_sms_batch

router = APIRouter()


# ─────────────────────────────────────────────────────────────
# POST /transactions/sync
# ─────────────────────────────────────────────────────────────
@router.post(
    "/sync",
    response_model=schemas.TransactionSyncResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Batch-import SMS messages and auto-parse into transactions",
)
async def sync_transactions(
    payload: schemas.TransactionSyncRequest,
    db: AsyncSession = Depends(get_db),
):
    """
    Accepts a list of raw SMS bodies from the Flutter app.
    Each SMS is parsed with the Regex engine, categorised, and stored.
    Duplicate reference IDs are silently skipped.
    """
    # Verify user exists
    user = await crud.get_user(db, payload.user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Build raw message dicts for the parser
    raw_msgs = [
        {"raw_text": sms.raw_text, "received_at": sms.received_at}
        for sms in payload.sms_messages
    ]

    parsed_list, failed_texts = parse_sms_batch(raw_msgs)

    # Map ParsedSMS → TransactionCreate
    tx_creates: List[schemas.TransactionCreate] = []
    for p in parsed_list:
        tx_creates.append(
            schemas.TransactionCreate(
                amount=p.amount,
                transaction_type=p.transaction_type,
                merchant=p.merchant,
                category=p.category,
                reference_id=p.reference_id,
                bank_name=p.bank_name,
                account_last4=p.account_last4,
                balance_after=p.balance_after,
                transacted_at=p.transacted_at,
                raw_text=p.raw_text,
                is_sms_parsed=True,
            )
        )

    created = await crud.bulk_create_transactions(db, payload.user_id, tx_creates)

    return schemas.TransactionSyncResponse(
        total_received=len(payload.sms_messages),
        successfully_parsed=len(created),
        failed_to_parse=len(failed_texts),
        transactions=[schemas.TransactionResponse.model_validate(t) for t in created],
    )


# ─────────────────────────────────────────────────────────────
# GET /transactions/
# ─────────────────────────────────────────────────────────────
@router.get(
    "/",
    response_model=List[schemas.TransactionResponse],
    summary="List recent transactions for a user",
)
async def list_transactions(
    user_id: int,
    skip: int = 0,
    limit: int = 50,
    db: AsyncSession = Depends(get_db),
):
    user = await crud.get_user(db, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    txns = await crud.get_transactions(db, user_id, skip=skip, limit=limit)
    return txns
