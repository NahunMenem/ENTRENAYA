from datetime import datetime, timezone
from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User


class UserRepository:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def upsert_google_identity(self, identity: dict[str, Any]) -> User:
        google_subject = identity["sub"]
        email = identity["email"].strip().lower()
        result = await self.db.execute(
            select(User).where(User.google_subject == google_subject)
        )
        user = result.scalar_one_or_none()

        if user is None:
            result = await self.db.execute(select(User).where(User.email == email))
            user = result.scalar_one_or_none()
            if user is not None and user.google_subject != google_subject:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="Ese email ya está asociado a otra cuenta.",
                )
            if user is None:
                user = User(google_subject=google_subject, email=email)
                self.db.add(user)

        user.email = email
        user.full_name = identity.get("name")
        user.picture_url = identity.get("picture")
        user.email_verified = True
        user.last_login_at = datetime.now(timezone.utc)

        try:
            await self.db.commit()
        except IntegrityError as exc:
            await self.db.rollback()
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="No se pudo asociar esta cuenta de Google con el usuario existente.",
            ) from exc

        await self.db.refresh(user)
        return user
