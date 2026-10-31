from fastapi import APIRouter, Depends
from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.models.exercise import Exercise
from app.models.catalog import ExerciseInfo
from app.api.v1.catalog_admin import exercise_data

router = APIRouter(prefix="/exercises", tags=["Ejercicios"])


@router.get("")
async def list_exercises(db: AsyncSession = Depends(get_db)) -> list[dict]:
    rows = (await db.execute(select(Exercise, ExerciseInfo).outerjoin(ExerciseInfo)
        .where(or_(ExerciseInfo.published.is_(True), ExerciseInfo.id.is_(None)))
        .order_by(Exercise.name))).all()
    return [exercise_data(row, info) for row, info in rows]
