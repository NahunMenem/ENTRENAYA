from secrets import compare_digest
import asyncio
from typing import Literal
from uuid import uuid4

from fastapi import APIRouter, Depends, Header, HTTPException
from pydantic import BaseModel, Field, HttpUrl, field_validator, model_validator
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import get_settings
from app.db.session import get_db
from app.models.exercise import Exercise
from app.models.catalog import ExerciseInfo, RoutineTemplate
from app.models.exercise_cover import ExerciseCover
from app.services.exercise_cover import process_cover, upload_cover


def require_admin(x_admin_key: str = Header(default="")) -> None:
    configured = get_settings().admin_api_key
    if configured is None or len(configured.get_secret_value()) < 32:
        raise HTTPException(503, "Acceso administrativo sin configurar.")
    if not compare_digest(x_admin_key, configured.get_secret_value()):
        raise HTTPException(401, "Acceso administrativo requerido.")


router = APIRouter(prefix="/admin", tags=["Administración"], dependencies=[Depends(require_admin)])
public_router = APIRouter(tags=["Rutinas"])


class ExerciseInput(BaseModel):
    name: str = Field(min_length=2, max_length=255)
    muscle_group: str = Field(min_length=2, max_length=80)
    equipment: str = Field(default="", max_length=120)
    instructions: str = Field(default="", max_length=10000)
    video_url: HttpUrl | None = None
    cover_image: str | None = Field(default=None, max_length=5_600_000)
    remove_cover: bool = False
    published: bool = False

    @field_validator("name", "muscle_group")
    @classmethod
    def nonblank(cls, value: str) -> str:
        if len(value.strip()) < 2:
            raise ValueError("Completá este campo.")
        return value.strip()

    @field_validator("video_url")
    @classmethod
    def https_video(cls, value: HttpUrl | None) -> HttpUrl | None:
        if value is not None and value.scheme != "https":
            raise ValueError("El video debe usar HTTPS.")
        return value


class TemplateExercise(BaseModel):
    id: str = Field(min_length=1, max_length=100)
    sets: int = Field(ge=1, le=10)
    reps: int = Field(ge=1, le=50)
    rest_seconds: int = Field(ge=0, le=300)


class TemplateInput(BaseModel):
    name: str = Field(min_length=2, max_length=100)
    category: Literal["Hipertrofia", "Déficit", "Volumen", "Fuerza", "Mantenimiento"]
    level: Literal["Principiante", "Intermedio", "Avanzado"]
    description: str = Field(default="", max_length=5000)
    days: list[int] = Field(min_length=1, max_length=7)
    exercises: list[TemplateExercise] = Field(min_length=1, max_length=40)
    published: bool = False

    @model_validator(mode="after")
    def valid_routine(self):
        self.name = self.name.strip()
        if len(self.name) < 2 or any(d < 1 or d > 7 for d in self.days) or len(set(self.days)) != len(self.days):
            raise ValueError("Revisá el nombre y los días de la rutina.")
        if len({e.id for e in self.exercises}) != len(self.exercises):
            raise ValueError("No repitas el mismo ejercicio en una rutina.")
        return self


def exercise_data(exercise: Exercise, info: ExerciseInfo | None, cover_url: str | None = None) -> dict:
    return dict(id=exercise.id, name=exercise.name, video_url=exercise.video_url,
        muscle_group=info.muscle_group if info else "Otros", equipment=info.equipment if info else "",
        instructions=info.instructions if info else "", published=info.published if info else True,
        cover_url=cover_url)


@router.get("/exercises")
async def exercises(db: AsyncSession = Depends(get_db)) -> list[dict]:
    rows = (await db.execute(select(Exercise, ExerciseInfo, ExerciseCover.url).outerjoin(ExerciseInfo).outerjoin(ExerciseCover).order_by(Exercise.name))).all()
    return [exercise_data(row, info, url) for row, info, url in rows]


async def save_exercise(data: ExerciseInput, db: AsyncSession, exercise_id: str | None = None) -> dict:
    processed = await asyncio.to_thread(process_cover, data.cover_image) if data.cover_image else None
    row = await db.get(Exercise, exercise_id) if exercise_id else Exercise(id=str(uuid4()))
    if row is None:
        raise HTTPException(404, "Ejercicio no encontrado.")
    if not data.published:
        templates = (await db.scalars(select(RoutineTemplate).where(RoutineTemplate.published.is_(True)))).all()
        if any(any(e["id"] == row.id for e in template.exercises) for template in templates):
            raise HTTPException(409, "Pasá a borrador las rutinas publicadas que usan este ejercicio primero.")
    info = await db.get(ExerciseInfo, row.id) if exercise_id else None
    info = info or ExerciseInfo(id=row.id)
    row.name, row.video_url = data.name, str(data.video_url) if data.video_url else None
    for key in ("muscle_group", "equipment", "instructions", "published"):
        setattr(info, key, getattr(data, key))
    db.add(row)
    await db.flush()
    db.add(info)
    cover = await db.get(ExerciseCover, row.id) if exercise_id else None
    if data.remove_cover and not processed and cover is not None:
        await db.delete(cover)
        cover = None
    if processed:
        url, public_id = await asyncio.to_thread(upload_cover, processed[0], row.id)
        cover = cover or ExerciseCover(id=row.id)
        cover.url, cover.public_id, cover.checksum = url, public_id, processed[1]
        db.add(cover)
    await db.commit()
    return exercise_data(row, info, cover.url if cover else None)


@router.post("/exercises", status_code=201)
async def create_exercise(data: ExerciseInput, db: AsyncSession = Depends(get_db)):
    return await save_exercise(data, db)


@router.put("/exercises/{exercise_id}")
async def update_exercise(exercise_id: str, data: ExerciseInput, db: AsyncSession = Depends(get_db)):
    return await save_exercise(data, db, exercise_id)


async def template_data(template: RoutineTemplate, db: AsyncSession) -> dict:
    ids = [e["id"] for e in template.exercises]
    names = {e.id: e.name for e in (await db.scalars(select(Exercise).where(Exercise.id.in_(ids)))).all()}
    return dict(id=template.id, name=template.name, category=template.category, level=template.level,
        description=template.description, days=template.days, published=template.published,
        exercises=[{**e, "name": names.get(e["id"], "Ejercicio")} for e in template.exercises])


@router.get("/routines")
async def routines(db: AsyncSession = Depends(get_db)):
    rows = (await db.scalars(select(RoutineTemplate).order_by(RoutineTemplate.name))).all()
    return [await template_data(row, db) for row in rows]


async def save_template(data: TemplateInput, db: AsyncSession, template_id: str | None = None):
    template = await db.get(RoutineTemplate, template_id) if template_id else RoutineTemplate(id=str(uuid4()))
    if template is None:
        raise HTTPException(404, "Rutina no encontrada.")
    ids = [e.id for e in data.exercises]
    rows = (await db.execute(select(Exercise, ExerciseInfo).outerjoin(ExerciseInfo).where(Exercise.id.in_(ids)))).all()
    if len(rows) != len(ids):
        raise HTTPException(422, "La rutina contiene ejercicios que no existen.")
    if data.published and any(info is not None and not info.published for _, info in rows):
        raise HTTPException(422, "Publicá todos los ejercicios antes de publicar la rutina.")
    for key in ("name", "category", "level", "description", "days", "published"):
        setattr(template, key, getattr(data, key))
    template.exercises = [e.model_dump() for e in data.exercises]
    db.add(template)
    await db.commit()
    return await template_data(template, db)


@router.post("/routines", status_code=201)
async def create_template(data: TemplateInput, db: AsyncSession = Depends(get_db)):
    return await save_template(data, db)


@router.put("/routines/{template_id}")
async def update_template(template_id: str, data: TemplateInput, db: AsyncSession = Depends(get_db)):
    return await save_template(data, db, template_id)


@public_router.get("/routines")
async def published_routines(db: AsyncSession = Depends(get_db)):
    rows = (await db.scalars(select(RoutineTemplate).where(RoutineTemplate.published.is_(True)).order_by(RoutineTemplate.name))).all()
    return [await template_data(row, db) for row in rows]


@public_router.get("/routines/{routine_id}")
async def shared_routine(routine_id: str, db: AsyncSession = Depends(get_db)):
    row = await db.get(RoutineTemplate, routine_id)
    if row is None or not row.published:
        raise HTTPException(404, "Ese código no corresponde a una rutina publicada. Revisalo con tu profe.")
    return await template_data(row, db)
