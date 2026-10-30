from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr, Field, HttpUrl


class GoogleLoginRequest(BaseModel):
    id_token: str = Field(min_length=1, max_length=10000)


class UserProfile(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: str
    email: EmailStr
    name: str | None = None
    picture: HttpUrl | None = None
    email_verified: bool = True
    provider: str = "google"


class GoogleLoginResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_at: datetime
    user: UserProfile
