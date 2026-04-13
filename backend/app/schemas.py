"""
ScholarSpend AI — Pydantic v2 Schemas
Used for request/response validation in FastAPI endpoints.
"""

from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator

from app.models import BillingCycle, TransactionCategory, TransactionType


# ─────────────────────────────────────────────
# Shared Config
# ─────────────────────────────────────────────
class OrmBase(BaseModel):
    """Base class that enables ORM mode for all response schemas."""

    model_config = ConfigDict(from_attributes=True)


# ═══════════════════════════════════════════════════════════════
# USER SCHEMAS
# ═══════════════════════════════════════════════════════════════


class UserCreate(BaseModel):
    """Payload to register a new user."""

    email: EmailStr
    password: str = Field(..., min_length=8, description="Minimum 8 characters")
    full_name: Optional[str] = Field(None, max_length=150)
    phone_number: Optional[str] = Field(
        None,
        pattern=r"^\+?[1-9]\d{6,14}$",
        description="E.164 format, e.g. +919876543210",
    )
    current_balance: float = Field(0.0, ge=0, description="Opening balance in chosen currency")
    currency: str = Field("INR", max_length=10)


class UserUpdate(BaseModel):
    """Payload for partial user profile updates."""

    full_name: Optional[str] = Field(None, max_length=150)
    phone_number: Optional[str] = Field(None, pattern=r"^\+?[1-9]\d{6,14}$")
    current_balance: Optional[float] = Field(None, ge=0)
    currency: Optional[str] = Field(None, max_length=10)


class UserResponse(OrmBase):
    """Safe user representation returned from the API (no password)."""

    id: int
    email: EmailStr
    full_name: Optional[str]
    phone_number: Optional[str]
    current_balance: float
    currency: str
    is_active: bool
    is_verified: bool
    created_at: datetime
    updated_at: datetime


class UserWithStats(UserResponse):
    """Extended user response including survival analytics."""

    days_of_survival: Optional[float] = Field(
        None,
        description="Calculated as current_balance / avg_daily_spend",
    )
    predicted_crash_date: Optional[datetime] = Field(
        None,
        description="Forecasted zero-balance date from the ML engine",
    )


# ═══════════════════════════════════════════════════════════════
# TRANSACTION SCHEMAS
# ═══════════════════════════════════════════════════════════════


class SMSPayload(BaseModel):
    """
    Represents a single raw SMS message forwarded from the Flutter app.
    The backend SMS parser will extract structured data from `raw_text`.
    """

    raw_text: str = Field(..., description="Complete SMS body as received")
    received_at: Optional[datetime] = Field(
        None,
        description="Timestamp when the SMS was received on the device",
    )
    sender: Optional[str] = Field(
        None,
        max_length=50,
        description="Sender ID, e.g. 'VM-HDFCBK'",
    )


class TransactionCreate(BaseModel):
    """
    Payload for manually creating a transaction OR
    the result of SMS parsing before insertion.
    """

    amount: float = Field(..., gt=0, description="Absolute transaction amount")
    transaction_type: TransactionType = TransactionType.DEBIT
    merchant: Optional[str] = Field(None, max_length=255)
    description: Optional[str] = Field(None, max_length=500)
    category: TransactionCategory = TransactionCategory.OTHER
    reference_id: Optional[str] = Field(None, max_length=100)
    bank_name: Optional[str] = Field(None, max_length=100)
    account_last4: Optional[str] = Field(None, max_length=4)
    balance_after: Optional[float] = None
    transacted_at: Optional[datetime] = None

    # SMS origin fields (populated when parsed from SMS)
    raw_text: Optional[str] = Field(None, description="Original SMS body if auto-imported")
    is_sms_parsed: bool = False

    @field_validator("account_last4")
    @classmethod
    def validate_last4(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and not v.isdigit():
            raise ValueError("account_last4 must contain only digits")
        return v


class TransactionSyncRequest(BaseModel):
    """
    Payload for POST /transactions/sync.
    Accepts a batch of raw SMS messages from the Flutter app.
    The backend parses each SMS and creates Transaction records.
    """

    user_id: int
    sms_messages: List[SMSPayload] = Field(
        ...,
        min_length=1,
        description="One or more raw SMS bodies to parse and persist",
    )


class TransactionSyncResponse(BaseModel):
    """Response from POST /transactions/sync."""

    total_received: int
    successfully_parsed: int
    failed_to_parse: int
    transactions: List["TransactionResponse"]


class TransactionResponse(OrmBase):
    """Full transaction record returned from the API."""

    id: int
    user_id: int
    amount: float
    transaction_type: TransactionType
    merchant: Optional[str]
    description: Optional[str]
    raw_text: Optional[str]
    is_sms_parsed: bool
    category: TransactionCategory
    reference_id: Optional[str]
    bank_name: Optional[str]
    account_last4: Optional[str]
    balance_after: Optional[float]
    transacted_at: datetime
    created_at: datetime
    updated_at: datetime


# Allow self-referential model
TransactionSyncResponse.model_rebuild()


# ═══════════════════════════════════════════════════════════════
# SUBSCRIPTION SCHEMAS
# ═══════════════════════════════════════════════════════════════


class SubscriptionCreate(BaseModel):
    """Payload to add a recurring subscription."""

    name: str = Field(..., max_length=255, description="e.g. 'Netflix Premium'")
    amount: float = Field(..., gt=0)
    billing_cycle: BillingCycle = BillingCycle.MONTHLY
    category: TransactionCategory = TransactionCategory.SUBSCRIPTION
    next_billing_date: Optional[datetime] = None
    is_active: bool = True


class SubscriptionUpdate(BaseModel):
    """Partial update payload for a subscription."""

    name: Optional[str] = Field(None, max_length=255)
    amount: Optional[float] = Field(None, gt=0)
    billing_cycle: Optional[BillingCycle] = None
    category: Optional[TransactionCategory] = None
    next_billing_date: Optional[datetime] = None
    is_active: Optional[bool] = None


class SubscriptionResponse(OrmBase):
    """Subscription record returned from the API."""

    id: int
    user_id: int
    name: str
    amount: float
    billing_cycle: BillingCycle
    category: TransactionCategory
    next_billing_date: Optional[datetime]
    is_active: bool
    auto_detected: bool
    created_at: datetime
    updated_at: datetime


# ═══════════════════════════════════════════════════════════════
# ANALYTICS / SURVIVAL FORECAST SCHEMAS
# ═══════════════════════════════════════════════════════════════


class SpendingBreakdown(BaseModel):
    """Per-category spending summary for a given period."""

    category: TransactionCategory
    total_spent: float
    transaction_count: int
    percentage_of_total: float


class SurvivalForecastResponse(BaseModel):
    """
    Response from GET /analytics/survival-forecast.
    Powers the ScholarSpend AI Survival Counter dashboard.
    """

    user_id: int
    current_balance: float
    currency: str

    # Core survival metric
    avg_daily_spend: float = Field(
        ..., description="Rolling average daily expenditure (last 30 days)"
    )
    days_of_survival: float = Field(
        ..., description="current_balance / avg_daily_spend"
    )
    predicted_crash_date: Optional[datetime] = Field(
        None,
        description="Forecasted date the balance hits zero (NumPy linear regression)",
    )

    # Subscription burn
    monthly_subscription_cost: float
    active_subscriptions: List[SubscriptionResponse]

    # Spending breakdown
    spending_breakdown: List[SpendingBreakdown]

    # Metadata
    forecast_generated_at: datetime = Field(default_factory=datetime.utcnow)
    data_window_days: int = Field(30, description="Days of history used for forecast")
