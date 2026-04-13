"""
ScholarSpend AI — Predictive Crash Alert Engine
Uses NumPy linear regression on daily spend history to forecast
the date the student's balance will reach zero.

Algorithm:
  1. Build a time-series of cumulative spend from the last N days.
  2. Fit a linear regression (numpy.polyfit degree-1) on (day_index, cumulative_spend).
  3. Solve for the day_index when projected balance = 0.
  4. Also incorporate fixed recurring subscription costs.
"""

from datetime import datetime, timedelta
from typing import Optional

import numpy as np


# ─────────────────────────────────────────────
# Result dataclass
# ─────────────────────────────────────────────
class ForecastResult:
    def __init__(
        self,
        avg_daily_spend: float,
        days_of_survival: float,
        predicted_crash_date: Optional[datetime],
        monthly_subscription_cost: float,
        confidence: float,
    ):
        self.avg_daily_spend = round(avg_daily_spend, 2)
        self.days_of_survival = round(days_of_survival, 1)
        self.predicted_crash_date = predicted_crash_date
        self.monthly_subscription_cost = round(monthly_subscription_cost, 2)
        self.confidence = round(confidence, 2)      # R² of the regression fit

    def __repr__(self) -> str:
        return (
            f"<ForecastResult avg_daily={self.avg_daily_spend} "
            f"days_left={self.days_of_survival} "
            f"crash={self.predicted_crash_date}>"
        )


# ─────────────────────────────────────────────
# Core Engine
# ─────────────────────────────────────────────

def _r_squared(y_actual: np.ndarray, y_predicted: np.ndarray) -> float:
    """Coefficient of determination (R²) for the regression line."""
    ss_res = np.sum((y_actual - y_predicted) ** 2)
    ss_tot = np.sum((y_actual - np.mean(y_actual)) ** 2)
    if ss_tot == 0:
        return 1.0
    return float(1 - ss_res / ss_tot)


def compute_survival_forecast(
    current_balance: float,
    daily_spend_history: list[dict],   # [{"day": date, "total": float}, ...]
    monthly_subscription_cost: float = 0.0,
    min_data_points: int = 3,
) -> ForecastResult:
    """
    Primary forecasting function.

    Args:
        current_balance:          The user's current account balance.
        daily_spend_history:      List of {"day": date, "total": float} from CRUD.
        monthly_subscription_cost: Sum of all active subscription amounts per month.
        min_data_points:          Minimum days of data required for regression.
                                  Falls back to simple average if below threshold.

    Returns:
        ForecastResult with avg_daily_spend, days_of_survival, predicted_crash_date.
    """
    # Convert subscription cost to daily
    daily_subscription = monthly_subscription_cost / 30.0

    # ── Insufficient data: use subscription cost as floor ──────────
    if len(daily_spend_history) < min_data_points:
        avg_daily = daily_subscription or 1.0       # avoid division by zero
        days_left = current_balance / avg_daily
        crash_date = datetime.utcnow() + timedelta(days=days_left) if days_left > 0 else datetime.utcnow()
        return ForecastResult(
            avg_daily_spend=avg_daily,
            days_of_survival=days_left,
            predicted_crash_date=crash_date,
            monthly_subscription_cost=monthly_subscription_cost,
            confidence=0.0,
        )

    # ── Build numpy arrays ─────────────────────────────────────────
    amounts = np.array([d["total"] for d in daily_spend_history], dtype=float)
    x = np.arange(len(amounts), dtype=float)   # day indices: 0, 1, 2, ...

    # ── Linear regression: spend = slope * day + intercept ─────────
    coeffs = np.polyfit(x, amounts, 1)
    slope, intercept = float(coeffs[0]), float(coeffs[1])

    # Predicted values for R²
    y_pred = np.polyval(coeffs, x)
    r2 = _r_squared(amounts, y_pred)

    # ── Average daily spend (regression-smoothed) ──────────────────
    avg_daily_organic = float(np.mean(amounts))
    # Blend regression trend with simple mean for stability
    blend_weight = min(max(r2, 0.0), 1.0)
    projected_next_day = float(np.polyval(coeffs, len(amounts)))
    avg_daily = (blend_weight * projected_next_day) + ((1 - blend_weight) * avg_daily_organic)

    # Add subscription daily cost
    avg_daily_total = max(avg_daily + daily_subscription, 0.01)

    # ── Days of survival ───────────────────────────────────────────
    days_left = current_balance / avg_daily_total

    # ── Crash date ─────────────────────────────────────────────────
    predicted_crash_date: Optional[datetime] = None
    if days_left > 0:
        predicted_crash_date = datetime.utcnow() + timedelta(days=days_left)

    return ForecastResult(
        avg_daily_spend=avg_daily_total,
        days_of_survival=days_left,
        predicted_crash_date=predicted_crash_date,
        monthly_subscription_cost=monthly_subscription_cost,
        confidence=r2,
    )


def compute_monthly_subscription_cost(
    subscriptions: list[dict],
) -> float:
    """
    Normalises all active subscriptions to a monthly cost.

    Each subscription dict should have:
      {"amount": float, "billing_cycle": BillingCycle_string}
    """
    from app.models import BillingCycle   # local import to avoid circular

    multiplier_map = {
        BillingCycle.DAILY:   30.0,
        BillingCycle.WEEKLY:  4.33,
        BillingCycle.MONTHLY: 1.0,
        BillingCycle.YEARLY:  1 / 12,
    }

    total = 0.0
    for sub in subscriptions:
        cycle = sub.get("billing_cycle", BillingCycle.MONTHLY)
        amount = float(sub.get("amount", 0))
        multiplier = multiplier_map.get(cycle, 1.0)
        total += amount * multiplier
    return total
