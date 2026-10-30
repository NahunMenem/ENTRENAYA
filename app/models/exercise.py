from sqlalchemy import String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class Exercise(Base):
    __tablename__ = "exercises"

    id: Mapped[str] = mapped_column(String(100), primary_key=True)
    name: Mapped[str] = mapped_column(String(255))
    # Public HTTPS playback URL supplied by the future administrator panel.
    video_url: Mapped[str | None] = mapped_column(String(2048), nullable=True)
