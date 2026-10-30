from typing import Any
from uuid import UUID

from fastapi import HTTPException, status
from fastapi.concurrency import run_in_threadpool
from google.auth.exceptions import GoogleAuthError
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token as google_id_token
from pydantic import ValidationError

from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import get_settings
from app.core.security import create_access_token, decode_access_token
from app.models.user import User
from app.repositories.user import UserRepository
from app.schemas.auth import GoogleLoginResponse, UserProfile


class AuthService:
    def __init__(self, db: AsyncSession):
        self.db = db
        self.user_repository = UserRepository(db)

    async def login_with_google(self, id_token: str) -> GoogleLoginResponse:
        settings = get_settings()
        if not settings.google_client_id:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="El acceso con Google todavía no está configurado.",
            )
        try:
            identity = await run_in_threadpool(
                google_id_token.verify_oauth2_token,
                id_token,
                google_requests.Request(),
                settings.google_client_id,
            )
        except ValueError as exc:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="El token de Google no es válido o expiró.",
            ) from exc
        except GoogleAuthError as exc:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="No se pudo validar la cuenta con Google. Intentá de nuevo.",
            ) from exc

        if not identity.get("email_verified"):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="La cuenta de Google debe tener el email verificado.",
            )

        self._validate_google_identity(identity)
        user = await self.user_repository.upsert_google_identity(identity)
        profile = self._profile_from_user(user)
        access_token, expires_at = create_access_token(
            {
                "sub": profile.id,
                "email": str(profile.email),
                "name": profile.name,
                "picture": str(profile.picture) if profile.picture else None,
                "email_verified": profile.email_verified,
                "provider": profile.provider,
            }
        )
        return GoogleLoginResponse(
            access_token=access_token,
            expires_at=expires_at,
            user=profile,
        )

    async def get_current_user(self, token: str) -> UserProfile:
        claims = decode_access_token(token)
        if claims is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="El token de acceso no es válido o expiró.",
                headers={"WWW-Authenticate": "Bearer"},
            )
        try:
            user = await self.db.get(User, UUID(claims["sub"]))
        except (KeyError, ValidationError, ValueError) as exc:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="El token de acceso no contiene un perfil válido.",
                headers={"WWW-Authenticate": "Bearer"},
            ) from exc
        if user is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="La cuenta asociada a este token ya no existe.",
                headers={"WWW-Authenticate": "Bearer"},
            )
        return self._profile_from_user(user)

    @staticmethod
    def _validate_google_identity(identity: dict[str, Any]) -> None:
        subject = identity.get("sub")
        email = identity.get("email")
        if not subject or not email:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Google no devolvió una identidad completa.",
            )

    @staticmethod
    def _profile_from_user(user: User) -> UserProfile:
        try:
            return UserProfile(
                id=str(user.id),
                email=user.email,
                name=user.full_name,
                picture=user.picture_url,
                email_verified=user.email_verified,
            )
        except ValidationError as exc:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="El perfil guardado no es válido.",
            ) from exc
