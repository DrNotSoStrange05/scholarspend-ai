"""
ScholarSpend AI — SQLAlchemy ORM Models
Database: PostgreSQL
Tables:  users, transactions, subscriptions
"""

import enum
from datetime import datetime

from sqlalchemy import (
    Boolean,
    Column,
    DateTime,
    Enum,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
)
from sqlalchemy.orm import DeclarativeBase, relationship
from sqlalchemy.sql import func


# ─────────────────────────────────────────────
# Base
# ─────────────────────────────────────────────
class Base(DeclarativeBase):
    pass


# ─────────────────────────────────────────────
# Enums
# ─────────────────────────────────────────────
class TransactionType(str, enum.Enum):
    DEBIT = "debit"
    CREDIT = "credit"


class TransactionCategory(str, enum.Enum):
    FOOD = "food"
    TRANSPORT = "transport"
    ENTERTAINMENT = "entertainment"
    EDUCATION = "education"
    HEALTH = "health"
    SHOPPING = "shopping"
    UTILITIES = "utilities"
    SUBSCRIPTION = "subscription"
    TRANSFER = "transfer"
    OTHER = "other"


class BillingCycle(str, enum.Enum):
    DAILY = "daily"
    WEEKLY = "weekly"
    MONTHLY = "monthly"
    YEARLY = "yearly"


# ─────────────────────────────────────────────
# User
# ─────────────────────────────────────────────
class User(Base):
    """
    Represents a student user of ScholarSpend AI.
    """

    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, nullable=False, index=True)
    hashed_password = Column(String(255), nullable=False)
    full_name = Column(String(150), nullable=True)
    phone_number = Column(String(20), unique=True, nullable=True)

    # Financial snapshot
    current_balance = Column(Float, nullable=False, default=0.0)
    currency = Column(String(10), nullable=False, default="INR")

    # Account status
    is_active = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=False)

    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # Relationships
    transactions = relationship(
        "Transaction", back_populates="user", cascade="all, delete-orphan"
    )
    subscriptions = relationship(
        "Subscription", back_populates="user", cascade="all, delete-orphan"
    )

    def __repr__(self) -> str:
        return f"<User id={self.id} email={self.email!r}>"


# ─────────────────────────────────────────────
# Transaction
# ─────────────────────────────────────────────
class Transaction(Base):
    """
    Records every financial event parsed from an SMS alert or added manually.

    Key fields for the ScholarSpend AI core logic:
      • raw_text  — the original SMS body, stored verbatim for audit/re-parsing
      • category  — auto-tagged result from the SMS parser / AI engine
      • is_sms_parsed — flag to distinguish auto-imported vs. manual entries
    """

    __tablename__ = "transactions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)

    # Core financial data
    amount = Column(Float, nullable=False)
    transaction_type = Column(Enum(TransactionType), nullable=False, default=TransactionType.DEBIT)
    merchant = Column(String(255), nullable=True)          # Parsed merchant name
    description = Column(String(500), nullable=True)      # Human-readable note

    # SMS parsing fields
    raw_text = Column(Text, nullable=True)                 # Original SMS body verbatim
    is_sms_parsed = Column(Boolean, default=False)        # True if auto-imported from SMS

    # Categorisation (from parser or user override)
    category = Column(
        Enum(TransactionCategory),
        nullable=False,
        default=TransactionCategory.OTHER,
    )

    # Reference / UPI / bank data
    reference_id = Column(String(100), nullable=True, unique=True, index=True)
    bank_name = Column(String(100), nullable=True)
    account_last4 = Column(String(4), nullable=True)

    # Balance snapshot at the time of this transaction
    balance_after = Column(Float, nullable=True)

    # When the transaction actually occurred (from SMS timestamp or user input)
    transacted_at = Column(DateTime(timezone=True), nullable=False, default=datetime.utcnow)

    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # Relationships
    user = relationship("User", back_populates="transactions")

    def __repr__(self) -> str:
        return (
            f"<Transaction id={self.id} user_id={self.user_id} "
            f"amount={self.amount} type={self.transaction_type.value!r}>"
        )


# ─────────────────────────────────────────────
# Subscription
# ─────────────────────────────────────────────
class Subscription(Base):
    """
    Tracks recurring charges (Netflix, Spotify, gym, etc.) used by the
    Predictive Crash Alert engine to forecast the zero-balance date.
    """

    __tablename__ = "subscriptions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)

    name = Column(String(255), nullable=False)             # e.g., "Netflix Premium"
    amount = Column(Float, nullable=False)                 # Charge per cycle
    billing_cycle = Column(
        Enum(BillingCycle), nullable=False, default=BillingCycle.MONTHLY
    )
    category = Column(
        Enum(TransactionCategory),
        nullable=False,
        default=TransactionCategory.SUBSCRIPTION,
    )

    # Next expected charge date — used by the forecasting engine
    next_billing_date = Column(DateTime(timezone=True), nullable=True)

    # Whether the subscription is currently active
    is_active = Column(Boolean, default=True)

    # Optional: auto-detected from transaction history
    auto_detected = Column(Boolean, default=False)

    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # Relationships
    user = relationship("User", back_populates="subscriptions")

    def __repr__(self) -> str:
        return (
            f"<Subscription id={self.id} name={self.name!r} "
            f"amount={self.amount} cycle={self.billing_cycle.value!r}>"
        )
