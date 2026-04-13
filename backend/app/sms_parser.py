"""
ScholarSpend AI — SMS Parser Service
Extracts structured transaction data from Indian bank SMS alerts using Regex.

Supported banks / wallets:
  • HDFC Bank
  • SBI
  • ICICI Bank
  • Axis Bank
  • Kotak Mahindra Bank
  • Paytm / PaytmBank
  • PhonePe UPI alerts
  • Generic fallback pattern
"""

import re
from dataclasses import dataclass, field
from datetime import datetime
from typing import Optional

from app.models import TransactionCategory, TransactionType


# ─────────────────────────────────────────────
# Result dataclass
# ─────────────────────────────────────────────
@dataclass
class ParsedSMS:
    amount: float
    transaction_type: TransactionType
    merchant: Optional[str] = None
    bank_name: Optional[str] = None
    account_last4: Optional[str] = None
    reference_id: Optional[str] = None
    balance_after: Optional[float] = None
    transacted_at: Optional[datetime] = None
    category: TransactionCategory = TransactionCategory.OTHER
    raw_text: str = ""
    confidence: float = 1.0       # 0.0–1.0


# ─────────────────────────────────────────────
# Regex Patterns
# ─────────────────────────────────────────────

# Amount: handles "Rs.", "INR", "₹", with/without commas
_AMOUNT = r"(?:Rs\.?|INR|₹)\s*([\d,]+(?:\.\d{1,2})?)"

# Balance: "Avl Bal", "Available Balance", "Bal"
_BALANCE = r"(?:Avl\.?\s*Bal(?:ance)?|Balance|Bal)[\s:]*(?:Rs\.?|INR|₹)?\s*([\d,]+(?:\.\d{1,2})?)"

# UPI / Reference ID
_REF = r"(?:Ref(?:\.?\s*No\.?|erence)?|UPI Ref|Txn\s*(?:ID|No))[:\s]*([A-Z0-9]{8,22})"

# Account last 4 digits
_ACCT = r"(?:A[/c]c?t?|account|card)[\s\w]*?(?:no\.?|ending|XX+)[:\s]*(\d{4})"

# Merchant / VPA (UPI)
_MERCHANT_UPI = r"(?:to|from|at|To VPA)\s+([A-Za-z0-9._@\-]+?)(?:\s+(?:on|via|using|Ref|UPI|with|has)|$)"

# Date patterns: "13 Apr 26", "13-04-2026", "Apr 13 2026"
_DATE_PATTERNS = [
    r"(\d{1,2}[-/]\d{1,2}[-/]\d{2,4})",
    r"(\d{1,2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+\d{2,4})",
    r"((?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+\d{1,2},?\s+\d{4})",
]

_DATE_FORMATS = [
    "%d-%m-%Y", "%d/%m/%Y", "%d-%m-%y", "%d/%m/%y",
    "%d %b %Y", "%d %b %y", "%b %d, %Y", "%b %d %Y",
]


# ─────────────────────────────────────────────
# Merchant → Category mapping
# ─────────────────────────────────────────────
_CATEGORY_KEYWORDS: dict[TransactionCategory, list[str]] = {
    TransactionCategory.FOOD: [
        "swiggy", "zomato", "dominos", "mcdonalds", "kfc", "subway",
        "restaurant", "cafe", "food", "pizza", "burger", "biryani",
    ],
    TransactionCategory.TRANSPORT: [
        "uber", "ola", "rapido", "metro", "irctc", "railway", "bus",
        "petrol", "fuel", "parking", "fastag", "redbus",
    ],
    TransactionCategory.ENTERTAINMENT: [
        "netflix", "hotstar", "prime video", "spotify", "youtube",
        "bookmyshow", "inox", "pvr", "gaming", "steam",
    ],
    TransactionCategory.EDUCATION: [
        "udemy", "coursera", "byju", "unacademy", "college", "university",
        "library", "book", "tuition",
    ],
    TransactionCategory.HEALTH: [
        "pharmacy", "apollo", "medplus", "hospital", "clinic",
        "doctor", "health", "medicine", "lab", "diagnostic",
    ],
    TransactionCategory.SHOPPING: [
        "amazon", "flipkart", "myntra", "meesho", "ajio", "nykaa",
        "mall", "store", "market", "shop",
    ],
    TransactionCategory.UTILITIES: [
        "electricity", "bescom", "mseb", "water", "gas", "broadband",
        "airtel", "jio", "bsnl", "vodafone", "recharge",
    ],
    TransactionCategory.SUBSCRIPTION: [
        "subscription", "renewal", "annual plan", "monthly plan",
    ],
}


def _infer_category(merchant: Optional[str], raw_text: str) -> TransactionCategory:
    """Rule-based category inference from merchant name and SMS body."""
    text = ((merchant or "") + " " + raw_text).lower()
    for category, keywords in _CATEGORY_KEYWORDS.items():
        if any(kw in text for kw in keywords):
            return category
    return TransactionCategory.OTHER


# ─────────────────────────────────────────────
# Helper extractors
# ─────────────────────────────────────────────

def _extract_amount(text: str) -> Optional[float]:
    m = re.search(_AMOUNT, text, re.IGNORECASE)
    if m:
        return float(m.group(1).replace(",", ""))
    return None


def _extract_balance(text: str) -> Optional[float]:
    m = re.search(_BALANCE, text, re.IGNORECASE)
    if m:
        return float(m.group(1).replace(",", ""))
    return None


def _extract_reference(text: str) -> Optional[str]:
    m = re.search(_REF, text, re.IGNORECASE)
    return m.group(1).strip() if m else None


def _extract_account(text: str) -> Optional[str]:
    m = re.search(_ACCT, text, re.IGNORECASE)
    return m.group(1) if m else None


def _extract_merchant(text: str) -> Optional[str]:
    m = re.search(_MERCHANT_UPI, text, re.IGNORECASE)
    if m:
        raw = m.group(1).strip().rstrip(".")
        # Clean UPI VPA: "merchant@upi" → "Merchant"
        name = raw.split("@")[0].replace(".", " ").title()
        return name if len(name) > 2 else None
    return None


def _extract_date(text: str) -> Optional[datetime]:
    for pattern in _DATE_PATTERNS:
        m = re.search(pattern, text, re.IGNORECASE)
        if m:
            date_str = m.group(1).strip()
            for fmt in _DATE_FORMATS:
                try:
                    return datetime.strptime(date_str, fmt)
                except ValueError:
                    continue
    return None


def _detect_transaction_type(text: str) -> TransactionType:
    """
    Detect debit vs credit from common SMS keywords.
    Credit wins only if explicit credit keywords appear without debit context.
    """
    lower = text.lower()
    credit_words = ["credited", "received", "credit", "deposited", "added to"]
    debit_words  = ["debited", "paid", "deducted", "payment of", "spent", "withdrawn"]

    credit_hit = any(w in lower for w in credit_words)
    debit_hit  = any(w in lower for w in debit_words)

    if credit_hit and not debit_hit:
        return TransactionType.CREDIT
    return TransactionType.DEBIT   # default to debit (safer for spend tracking)


def _detect_bank(text: str) -> Optional[str]:
    banks = {
        "HDFC": ["hdfc"],
        "SBI": ["sbi", "state bank"],
        "ICICI": ["icici"],
        "Axis": ["axis bank"],
        "Kotak": ["kotak"],
        "Paytm": ["paytm"],
        "PhonePe": ["phonepe"],
        "Amazon Pay": ["amazon pay"],
    }
    lower = text.lower()
    for name, keywords in banks.items():
        if any(k in lower for k in keywords):
            return name
    return None


# ─────────────────────────────────────────────
# Public API
# ─────────────────────────────────────────────

def parse_sms(raw_text: str, received_at: Optional[datetime] = None) -> Optional[ParsedSMS]:
    """
    Parse a raw bank SMS string into a `ParsedSMS` dataclass.
    Returns None if no amount could be extracted (non-financial SMS).

    Usage:
        result = parse_sms("HDFC Bank: Rs.350.00 debited from A/c XX4321 ...")
        if result:
            # use result.amount, result.category, etc.
    """
    if not raw_text or len(raw_text.strip()) < 10:
        return None

    amount = _extract_amount(raw_text)
    if amount is None:
        return None   # Can't parse without an amount

    merchant = _extract_merchant(raw_text)
    category = _infer_category(merchant, raw_text)

    return ParsedSMS(
        amount=amount,
        transaction_type=_detect_transaction_type(raw_text),
        merchant=merchant,
        bank_name=_detect_bank(raw_text),
        account_last4=_extract_account(raw_text),
        reference_id=_extract_reference(raw_text),
        balance_after=_extract_balance(raw_text),
        transacted_at=_extract_date(raw_text) or received_at,
        category=category,
        raw_text=raw_text,
        confidence=1.0,
    )


def parse_sms_batch(
    messages: list[dict],
) -> tuple[list[ParsedSMS], list[str]]:
    """
    Parse a list of {"raw_text": str, "received_at": datetime | None} dicts.
    Returns (successful_results, failed_raw_texts).
    """
    successful: list[ParsedSMS] = []
    failed:     list[str]       = []

    for msg in messages:
        result = parse_sms(msg.get("raw_text", ""), msg.get("received_at"))
        if result:
            successful.append(result)
        else:
            failed.append(msg.get("raw_text", ""))

    return successful, failed
