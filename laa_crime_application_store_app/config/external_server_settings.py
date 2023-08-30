from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class ServerSettings(BaseSettings):
    auth_id: str
    url: str


class NsmCaseworkerServerSettings(ServerSettings):
    model_config = SettingsConfigDict(
        extra="ignore", env_file=".env", env_file_encoding="utf-8"
    )

    auth_id: str = Field("default", env="NSM_CASEWORKER_AUTH_ID")
    url: str = Field("default", env="NSM_CASEWORKER_URL")


@lru_cache()
def get_external_server_settings():
    return NsmCaseworkerServerSettings()
