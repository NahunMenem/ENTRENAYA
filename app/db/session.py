import asyncio
import logging
from collections.abc import AsyncGenerator

from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.exc import SQLAlchemyError

from app.core.config import get_settings


def _async_database_url(url: str) -> str:
    if url.startswith("postgres://"):
        return url.replace("postgres://", "postgresql+asyncpg://", 1)
    if url.startswith("postgresql://"):
        return url.replace("postgresql://", "postgresql+asyncpg://", 1)
    return url


settings = get_settings()
logger = logging.getLogger(__name__)
engine = create_async_engine(
    _async_database_url(settings.database_url),
    pool_pre_ping=True,
)
SessionLocal = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with SessionLocal() as session:
        yield session


async def create_db_and_tables() -> None:
    # Import models so SQLAlchemy registers their tables on Base.metadata.
    from app.models import user  # noqa: F401
    from app.db.base import Base

    for attempt in range(1, 6):
        try:
            async with engine.begin() as connection:
                await connection.run_sync(Base.metadata.create_all)
            return
        except SQLAlchemyError:
            if attempt == 5:
                raise
            logger.warning(
                "PostgreSQL is not ready yet; retrying database initialization (%s/5).",
                attempt,
            )
            await asyncio.sleep(attempt * 2)


async def close_database() -> None:
    await engine.dispose()
