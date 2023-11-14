from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class DatabaseSettings(BaseSettings):
    model_config = SettingsConfigDict(
        extra="ignore", env_file=".env", env_file_encoding="utf-8"
    )

    postgres_username: str | None = None
    postgres_password: str | None = None
    postgres_hostname: str | None = None
    postgres_name: str | None = None


@lru_cache()
def get_database_settings():
    return DatabaseSettings()
