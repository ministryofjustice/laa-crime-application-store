from typing import List, Optional
from uuid import UUID

from pydantic import BaseModel, Field


class ApplicationNew(BaseModel):
    application_id: UUID | None
    json_schema_version: int | None
    application_state: str | None
    application_risk: str | None
    application_type: str | None
    application: dict | None
    events: Optional[List[dict]] = Field([])
