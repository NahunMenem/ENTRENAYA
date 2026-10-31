from fastapi import APIRouter

from app.api.v1.auth import router as auth_router
from app.api.v1.exercises import router as exercises_router
from app.api.v1.catalog_admin import router as admin_router, public_router

api_router = APIRouter(prefix="/api/v1")
api_router.include_router(auth_router)
api_router.include_router(exercises_router)
api_router.include_router(admin_router)
api_router.include_router(public_router)
