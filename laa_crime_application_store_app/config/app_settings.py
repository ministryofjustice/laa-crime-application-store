from functools import lru_cache

from pydantic import computed_field
from pydantic_settings import BaseSettings, SettingsConfigDict


class AppSettings(BaseSettings):
    model_config = SettingsConfigDict(
        extra="ignore", env_file=".env", env_file_encoding="utf-8"
    )

    app_name: str = "Laa Crime Application Store"
    app_repo: str = "https://github.com/ministryofjustice/laa-crime-application-store"
    contact_email: str = "crm457@digital.justice.gov.uk"
    contact_team: str = "CRM457"
    commit_id: str | None = None
    build_date: str | None = None
    build_tag: str | None = None
    app_branch: str | None = None
    sentry_dsn: str | None = None
    swagger_endpoint: str | None = None

    @computed_field
    @property
    def swagger_enabled(self) -> bool:
        return self.swagger_endpoint == "enabled"


@lru_cache()
def get_app_settings():
    return AppSettings()
