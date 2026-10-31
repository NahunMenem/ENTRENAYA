from functools import lru_cache

from pydantic import SecretStr, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "EntrenaYa API"
    environment: str = "development"
    google_client_id: str | None = None
    admin_api_key: SecretStr | None = None
    database_url: str
    jwt_secret_key: SecretStr
    access_token_expire_minutes: int = 60
    cors_origins: str = "http://localhost:3000,http://localhost:5173"
    jwt_issuer: str = "entrenaya-api"
    jwt_audience: str = "entrenaya-client"

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    @field_validator("google_client_id")
    @classmethod
    def normalize_google_client_id(cls, value: str | None) -> str | None:
        if value is None:
            return None
        value = value.strip()
        if not value or value == "your-client-id.apps.googleusercontent.com":
            return None
        return value

    @field_validator("jwt_secret_key")
    @classmethod
    def jwt_secret_must_be_strong(cls, value: SecretStr) -> SecretStr:
        secret = value.get_secret_value()
        if len(secret) < 32 or secret.startswith("replace-this-"):
            raise ValueError("JWT_SECRET_KEY debe tener al menos 32 caracteres aleatorios.")
        return value

    @property
    def allowed_origins(self) -> list[str]:
        return [origin.strip() for origin in self.cors_origins.split(",") if origin.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
