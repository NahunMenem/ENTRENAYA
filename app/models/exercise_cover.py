from sqlalchemy import ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column
from app.db.base import Base


class ExerciseCover(Base):
    __tablename__ = "exercise_covers"
    id: Mapped[str] = mapped_column(ForeignKey("exercises.id"), primary_key=True)
    url: Mapped[str] = mapped_column(String(2048))
    public_id: Mapped[str] = mapped_column(String(255))
    checksum: Mapped[str] = mapped_column(String(64))
