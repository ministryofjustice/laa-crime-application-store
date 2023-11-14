from datetime import datetime
from typing import List
from uuid import UUID, uuid4

from pydantic import BaseModel, Field


class BasicApplication(BaseModel):
    application_id: UUID = Field(default_factory=uuid4)
    version: int
    application_state: str
    application_risk: str
    application_type: str
    updated_at: datetime


class ApplicationResponse(BaseModel):
    applications: List[BasicApplication]
