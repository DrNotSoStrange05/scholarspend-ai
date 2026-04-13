"""
ScholarSpend AI — Analytics Router
GET /analytics/survival-forecast — Core survival counter endpoint.
GET /analytics/summary          — Monthly totals, category breakdown, 7-day balance trend.
"""

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app import crud, schemas
from app.database import get_db
from app.forecaster import compute_monthly_subscription_cost, compute_survival_forecast

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

    daily_history = await crud.get_daily_spend_last_n_days(db, user_id, data_window_days)

    subs_orm = await crud.get_subscriptions(db, user_id, active_only=True)
    sub_dicts = [
        {"amount": s.amount, "billing_cycle": s.billing_cycle}
        for s in subs_orm
    ]
    monthly_sub_cost = compute_monthly_subscription_cost(sub_dicts)

    forecast = compute_survival_forecast(
        current_balance=user.current_balance,
        daily_spend_history=daily_history,
        monthly_subscription_cost=monthly_sub_cost,
    )

    raw_breakdown = await crud.get_category_breakdown(db, user_id, data_window_days)
    spending_breakdown = [schemas.SpendingBreakdown(**row) for row in raw_breakdown]
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


@router.get(
    "/summary",
    response_model=schemas.AnalyticsSummaryResponse,
    summary="Current-month totals, category breakdown & 7-day balance trend",
)
async def analytics_summary(
    user_id: int,
    db: AsyncSession = Depends(get_db),
):
    """
    Lightweight analytics snapshot for the Flutter Analytics Screen.

    Returns:
      - total_spent_current_month: Sum of all debits since 1st of this month.
      - category_breakdown: Dict of category → spent amount for current month.
      - balance_trend: Daily debit totals for the last 7 days.
    """
    user = await crud.get_user(db, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    monthly_total = await crud.get_monthly_total(db, user_id)
    category_breakdown = await crud.get_category_breakdown_current_month(db, user_id)
    raw_trend = await crud.get_balance_trend_7days(db, user_id)
    balance_trend = [schemas.BalanceTrendPoint(**p) for p in raw_trend]

    return schemas.AnalyticsSummaryResponse(
        user_id=user_id,
        total_spent_current_month=monthly_total,
        category_breakdown=category_breakdown,
        balance_trend=balance_trend,
    )
