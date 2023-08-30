from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class ExternalServerSettings(BaseSettings):
    model_config = SettingsConfigDict(
        extra="ignore", env_file=".env", env_file_encoding="utf-8"
    )

    nsm_caseworker_auth_id: str
    nsm_caseworker_url: str

    def auth_id(self, scope: str = "nsm_caseworker") -> str:
        return getattr(self, f"{scope}_auth_id")

    def url(self, scope: str = "nsm_caseworker") -> str:
        return getattr(self, f"{scope}_url")


@lru_cache()
def get_external_server_settings():
    return ExternalServerSettings()
