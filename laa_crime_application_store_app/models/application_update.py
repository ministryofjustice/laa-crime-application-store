from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field


class ApplicationUpdate(BaseModel):
    application_id: UUID | None
    json_schema_version: int | None
    application_state: str | None
    application_risk: str | None
    updated_application_risk: Optional[str] = Field(None)
    application: dict | None
