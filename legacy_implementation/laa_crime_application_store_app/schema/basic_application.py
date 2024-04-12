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

    @staticmethod
    def transform_from_application(application):
        return BasicApplication(
            application_id=application.id,
            version=application.current_version,
            application_state=application.application_state,
            application_risk=application.application_risk,
            application_type=application.application_type,
            updated_at=application.updated_at,
        )


class ApplicationResponse(BaseModel):
    applications: List[BasicApplication]
