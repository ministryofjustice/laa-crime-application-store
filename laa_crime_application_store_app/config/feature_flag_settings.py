from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class FeatureFlagSettings(BaseSettings):
    model_config = SettingsConfigDict(
        extra="ignore", env_file=".env", env_file_encoding="utf-8"
    )
    roles_enabled: str = "False"


@lru_cache()
def get_feature_flag_settings():
    return FeatureFlagSettings()
