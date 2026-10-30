from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text

from app.api.v1.router import api_router
from app.core.config import get_settings
from app.db.session import close_database, create_db_and_tables, engine

settings = get_settings()


@asynccontextmanager
async def lifespan(_: FastAPI):
    await create_db_and_tables()
    yield
    await close_database()


app = FastAPI(
    title=settings.app_name,
    description="API inicial de EntrenaYa para autenticación con Google.",
    version="0.1.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type"],
)

app.include_router(api_router)


@app.get("/health", tags=["Salud"])
async def health() -> dict[str, str]:
    return {"status": "ok", "service": "entrenaya-api"}


@app.get("/health/ready", tags=["Salud"])
async def readiness() -> dict[str, str]:
    async with engine.connect() as connection:
        await connection.execute(text("SELECT 1"))
    return {"status": "ready", "database": "connected"}
