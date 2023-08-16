from uuid import UUID

from pydantic import BaseModel


class ApplicationUpdate(BaseModel):
    application_id: UUID | None
    json_schema_version: int | None
    application_state: str | None
    application: dict | None
