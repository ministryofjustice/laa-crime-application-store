from uuid import UUID

from pydantic import BaseModel


class ApplicationNew(BaseModel):
    application_id: UUID | None
    json_schema_version: int | None
    application_state: str | None
    application_risk: str | None
    application: dict | None

    class Config:
        schema_extra = {
            "example": {
                "application_id": "d7f509e8-309c-4262-a41d-ebbb44deab9e",
                "json_schema_version": 1,
                "application_state": "submitted",
                "application_risk": "high",
                "application": {"id": "d7f509e8-309c-4262-a41d-ebbb44deab9e"},
            }
        }
