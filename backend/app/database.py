"""
ScholarSpend AI — Database Configuration
Sets up the async SQLAlchemy engine and session for PostgreSQL.
"""

import os

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.models import Base

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "sqlite+aiosqlite:///./scholarspend_dev.db",   # dev default (no Postgres needed)
    # Production: postgresql+asyncpg://scholar:scholar@db:5432/scholarspend
)

_connect_args = {"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {}
engine = create_async_engine(DATABASE_URL, echo=True, future=True, connect_args=_connect_args)

AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


async def init_db() -> None:
    """Create all tables on startup (use Alembic for production migrations)."""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)


async def get_db() -> AsyncSession:  # type: ignore[return]
    """FastAPI dependency that yields a DB session per request."""
    async with AsyncSessionLocal() as session:
        yield session
