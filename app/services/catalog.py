from sqlalchemy import select
from sqlalchemy.dialects.postgresql import insert

from app.db.session import SessionLocal
from app.models.exercise import Exercise
from app.models.catalog import ExerciseInfo

STARTER_EXERCISES = (
    ("press-banca", "Press de banca", "Pecho"),
    ("aperturas-mancuernas", "Aperturas con mancuernas", "Pecho"),
    ("press-inclinado", "Press inclinado", "Pecho"),
    ("flexiones", "Flexiones", "Pecho"),
    ("remo-mancuerna", "Remo con mancuerna", "Espalda"),
    ("jalon-pecho", "Jalón al pecho", "Espalda"),
    ("remo-polea", "Remo en polea", "Espalda"),
    ("dominadas", "Dominadas", "Espalda"),
    ("sentadilla", "Sentadilla", "Piernas"),
    ("prensa", "Prensa de piernas", "Piernas"),
    ("zancadas", "Zancadas", "Piernas"),
    ("peso-muerto-rumano", "Peso muerto rumano", "Piernas"),
    ("hip-thrust", "Hip thrust", "Piernas"),
    ("elevacion-gemelos", "Elevación de gemelos", "Piernas"),
    ("press-militar", "Press militar", "Hombros"),
    ("elevaciones-laterales", "Elevaciones laterales", "Hombros"),
    ("curl-biceps", "Curl de bíceps", "Brazos"),
    ("curl-martillo", "Curl martillo", "Brazos"),
    ("fondos-banco", "Fondos en banco", "Brazos"),
    ("extension-triceps", "Extensión de tríceps", "Brazos"),
    ("plancha", "Plancha con toque de hombros", "Abdominales"),
    ("crunch", "Crunch abdominal", "Abdominales"),
)


async def seed_catalog() -> None:
    async with SessionLocal() as db:
        for exercise_id, name, group in STARTER_EXERCISES:
            await db.execute(insert(Exercise).values(id=exercise_id, name=name).on_conflict_do_nothing(index_elements=["id"]))
        records = (await db.scalars(select(Exercise))).all()
        groups = {exercise_id: group for exercise_id, _, group in STARTER_EXERCISES}
        for row in records:
            await db.execute(insert(ExerciseInfo).values(id=row.id, muscle_group=groups.get(row.id, "Otros"),
                equipment="", instructions="", published=True).on_conflict_do_nothing(index_elements=["id"]))
        await db.commit()
