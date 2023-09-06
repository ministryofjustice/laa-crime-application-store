from uuid import UUID

from pydantic import BaseModel


class ApplicationMetadata(BaseModel):
    id: UUID | None
    state: str | None
    risk: str | None
    current_version: int | None
