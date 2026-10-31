from fastapi import APIRouter, Depends, Header, HTTPException, Request, Response
from fastapi.responses import RedirectResponse
from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.models.exercise import Exercise
from app.models.catalog import ExerciseInfo
from app.models.exercise_cover import ExerciseCover
from app.api.v1.catalog_admin import exercise_data, require_admin

router = APIRouter(prefix="/exercises", tags=["Ejercicios"])


@router.get("")
async def list_exercises(db: AsyncSession = Depends(get_db)) -> list[dict]:
    rows = (await db.execute(select(Exercise, ExerciseInfo, ExerciseCover.url).outerjoin(ExerciseInfo).outerjoin(ExerciseCover)
        .where(or_(ExerciseInfo.published.is_(True), ExerciseInfo.id.is_(None)))
        .order_by(Exercise.name))).all()
    return [exercise_data(row, info, url) for row, info, url in rows]


@router.get("/{exercise_id}/cover")
async def get_cover(exercise_id: str, request: Request, x_admin_key: str = Header(default=""), db: AsyncSession = Depends(get_db)):
    info = await db.get(ExerciseInfo, exercise_id)
    if info is not None and not info.published:
        try:
            require_admin(x_admin_key)
        except HTTPException:
            raise HTTPException(404, "Portada no disponible.")
    cover = await db.get(ExerciseCover, exercise_id)
    if cover is None:
        raise HTTPException(404, "Este ejercicio todavía no tiene portada.")
    headers = {"ETag": f'"{cover.checksum}"', "Cache-Control": "public, max-age=0, must-revalidate",
        "X-Content-Type-Options": "nosniff"}
    if info is not None and not info.published:
        headers["Cache-Control"] = "private, no-store"
    if request.headers.get("if-none-match") == headers["ETag"]:
        return Response(status_code=304, headers=headers)
    return RedirectResponse(cover.url, status_code=302, headers=headers)
