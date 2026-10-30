from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.schemas.auth import GoogleLoginRequest, GoogleLoginResponse, UserProfile
from app.services.auth import AuthService

router = APIRouter(prefix="/auth", tags=["Autenticación"])
bearer_scheme = HTTPBearer(auto_error=False)


@router.post("/google", response_model=GoogleLoginResponse)
async def login_with_google(
    data: GoogleLoginRequest,
    db: AsyncSession = Depends(get_db),
) -> GoogleLoginResponse:
    """Validate a Google ID token and issue an EntrenaYa access token."""
    return await AuthService(db).login_with_google(data.id_token)


@router.get("/me", response_model=UserProfile)
async def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
    db: AsyncSession = Depends(get_db),
) -> UserProfile:
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Se requiere un token de acceso.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return await AuthService(db).get_current_user(credentials.credentials)
