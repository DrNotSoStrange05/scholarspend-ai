"""
ScholarSpend AI — FastAPI Application Entry Point
"""

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.database import init_db
from app.routers import analytics, dues, subscriptions, transactions, users


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Run startup tasks (DB init) then yield for the app lifecycle."""
    await init_db()
    yield


app = FastAPI(
    title="ScholarSpend AI API",
    description="Financial stability backend for students — survival counter, SMS parsing & predictive crash alerts.",
    version="1.0.0",
    lifespan=lifespan,
)

# ── CORS (allow Flutter app + localhost dev) ───────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   # Tighten in production: specify Flutter app origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Routers ────────────────────────────────────────────────────
app.include_router(users.router,         prefix="/users",         tags=["Users"])
app.include_router(transactions.router,  prefix="/transactions",  tags=["Transactions"])
app.include_router(subscriptions.router, prefix="/subscriptions", tags=["Subscriptions"])
app.include_router(analytics.router,     prefix="/analytics",     tags=["Analytics"])
app.include_router(dues.router,          prefix="/dues",           tags=["Dues"])


@app.get("/health", tags=["Health"])
async def health_check():
    return {"status": "ok", "service": "ScholarSpend AI"}
