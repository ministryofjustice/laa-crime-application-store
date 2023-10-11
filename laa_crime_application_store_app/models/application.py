from typing import List
from uuid import UUID, uuid4

from pydantic import BaseModel, Field


class Application(BaseModel):
    application_id: UUID = Field(default_factory=uuid4)
    version: int
    json_schema_version: int
    application_state: str
    application_risk: str
    application_type: str
    application: dict
    events: List[dict]
