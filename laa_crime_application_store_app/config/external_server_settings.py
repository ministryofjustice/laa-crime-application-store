from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class ServerSettings(BaseSettings):
    auth_id: str
    url: str


class NsmCaseworkerServerSettings(ServerSettings):
    model_config = SettingsConfigDict(
        extra="ignore",
        env_file=".env",
        env_file_encoding="utf-8",
        env_prefix="NSM_CASEWORKER_",
    )

    auth_id: str
    url: str


@lru_cache()
def get_external_server_settings():
    return NsmCaseworkerServerSettings()
