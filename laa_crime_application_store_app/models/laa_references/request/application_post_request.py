from uuid import UUID

from pydantic import BaseModel


class ApplicationPostRequest(BaseModel):
    claim_id: UUID | None
    json_schema_version: int | None
    application_state: str | None
    risk: str | None
    application: dict | None

    class Config:
        schema_extra = {
            "example": {
                "claim_id": "d7f509e8-309c-4262-a41d-ebbb44deab9e",
                "json_schema_version": 1,
                "application_state": "submitted",
                "risk": "high",
                "application": {"id": "d7f509e8-309c-4262-a41d-ebbb44deab9e"},
            }
        }
