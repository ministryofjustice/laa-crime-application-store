from pydantic_settings import BaseSettings
from functools import lru_cache

class AppSettings(BaseSettings):
    app_name: str = "Laa Crime Application Store"
    app_repo: str = "https://github.com/ministryofjustice/laa-crime-application-store"
    contact_email: str = "crm457@digital.justice.gov.uk"
    contact_team: str = "CRM457"
    commit_id: str | None = None
    build_date: str | None = None
    build_tag: str | None = None
    app_branch: str | None = None

    class Config:
        env_file = '.env'
        env_file_encoding = 'utf-8'
        extra = 'ignore'


@lru_cache()
def get_app_settings():
    return AppSettings()