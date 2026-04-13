"""
GET /analytics/survival-forecast — Core ScholarSpend AI endpoint.
Returns days-of-survival, predicted crash date, and spending breakdown.
"""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app import crud, schemas
from app.database import get_db
from app.forecaster import compute_monthly_subscription_cost, compute_survival_forecast
from app.models import BillingCycle

router = APIRouter()


@router.get(
    "/survival-forecast",
    response_model=schemas.SurvivalForecastResponse,
    summary="Survival counter — days left & predicted zero-balance date",
)
async def survival_forecast(
    user_id: int,
    data_window_days: int = 30,
    db: AsyncSession = Depends(get_db),
):
    """
    Core ScholarSpend AI analytics endpoint.

    Pipeline:
      1. Fetch user's current balance.
      2. Query daily debit totals for the last `data_window_days`.
      3. Fetch active subscriptions and normalise to monthly cost.
      4. Run NumPy linear regression to forecast days of survival and crash date.
      5. Return full breakdown for the Flutter dashboard.
    """
    user = await crud.get_user(db, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Daily spend history
    daily_history = await crud.get_daily_spend_last_n_days(db, user_id, data_window_days)

    # Active subscriptions
    subs_orm = await crud.get_subscriptions(db, user_id, active_only=True)
    sub_dicts = [
        {"amount": s.amount, "billing_cycle": s.billing_cycle}
        for s in subs_orm
    ]
    monthly_sub_cost = compute_monthly_subscription_cost(sub_dicts)

    # Run forecast
    forecast = compute_survival_forecast(
        current_balance=user.current_balance,
        daily_spend_history=daily_history,
        monthly_subscription_cost=monthly_sub_cost,
    )

    # Category breakdown
    raw_breakdown = await crud.get_category_breakdown(db, user_id, data_window_days)
    spending_breakdown = [schemas.SpendingBreakdown(**row) for row in raw_breakdown]

    # Subscription responses
    sub_responses = [schemas.SubscriptionResponse.model_validate(s) for s in subs_orm]

    return schemas.SurvivalForecastResponse(
        user_id=user_id,
        current_balance=user.current_balance,
        currency=user.currency,
        avg_daily_spend=forecast.avg_daily_spend,
        days_of_survival=forecast.days_of_survival,
        predicted_crash_date=forecast.predicted_crash_date,
        monthly_subscription_cost=monthly_sub_cost,
        active_subscriptions=sub_responses,
        spending_breakdown=spending_breakdown,
        data_window_days=data_window_days,
    )
