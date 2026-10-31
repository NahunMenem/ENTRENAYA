from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, JSON, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class ExerciseInfo(Base):
    __tablename__ = "exercise_info"

    id: Mapped[str] = mapped_column(ForeignKey("exercises.id"), primary_key=True)
    muscle_group: Mapped[str] = mapped_column(String(80), default="Otros")
    equipment: Mapped[str] = mapped_column(String(120), default="")
    instructions: Mapped[str] = mapped_column(Text, default="")
    published: Mapped[bool] = mapped_column(Boolean, default=True)


class RoutineTemplate(Base):
    __tablename__ = "routine_templates"

    id: Mapped[str] = mapped_column(String(100), primary_key=True)
    name: Mapped[str] = mapped_column(String(100))
    category: Mapped[str] = mapped_column(String(40))
    level: Mapped[str] = mapped_column(String(40))
    description: Mapped[str] = mapped_column(Text, default="")
    days: Mapped[list] = mapped_column(JSON)
    exercises: Mapped[list] = mapped_column(JSON)
    published: Mapped[bool] = mapped_column(Boolean, default=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
