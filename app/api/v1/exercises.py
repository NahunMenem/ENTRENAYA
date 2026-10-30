from fastapi import APIRouter, Depends
from pydantic import BaseModel, HttpUrl
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.models.exercise import Exercise

router = APIRouter(prefix="/exercises", tags=["Ejercicios"])

DEFAULT_EXERCISES = (
    ("press-banca", "Press de banca"),
    ("aperturas-mancuernas", "Aperturas con mancuernas"),
    ("press-inclinado", "Press inclinado"),
    ("flexiones", "Flexiones"),
    ("fondos-banco", "Fondos en banco"),
    ("extension-triceps", "Extensión de tríceps"),
)


class ExerciseResponse(BaseModel):
    id: str
    name: str
    video_url: HttpUrl | None = None


@router.get("", response_model=list[ExerciseResponse])
async def list_exercises(db: AsyncSession = Depends(get_db)) -> list[ExerciseResponse]:
    """Return the starter catalog with any administrator-managed database values."""
    records = {row.id: row for row in (await db.scalars(select(Exercise))).all()}
    result = []
    for exercise_id, default_name in DEFAULT_EXERCISES:
        row = records.pop(exercise_id, None)
        result.append(ExerciseResponse(
            id=exercise_id,
            name=row.name if row else default_name,
            video_url=row.video_url if row else None,
        ))
    result.extend(ExerciseResponse(id=row.id, name=row.name, video_url=row.video_url)
                  for row in sorted(records.values(), key=lambda item: item.id))
    return result
