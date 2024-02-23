from functools import lru_cache

from pydantic import computed_field
from pydantic_settings import BaseSettings, SettingsConfigDict


class AuthSettings(BaseSettings):
    model_config = SettingsConfigDict(
        extra="ignore", env_file=".env", env_file_encoding="utf-8"
    )

    app_client_id: str = ""
    tenant_id: str = ""
    scope_description: str = ".default"
    azure_authentication: bool = True
    safe_clients: list[str] = []

    @computed_field
    @property
    def scope_name(self) -> str:
        return f"{self.app_client_id}/{self.scope_description}"

    @computed_field
    @property
    def scopes(self) -> dict:
        return {
            self.scope_name: self.scope_description,
        }


@lru_cache()
def get_auth_settings():
    return AuthSettings()
