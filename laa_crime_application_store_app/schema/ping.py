from typing import Optional

from pydantic import BaseModel, Field


class Ping(BaseModel):
    app_branch: Optional[str] = Field(
        None, json_schema_extra={"example": "test_branch"}
    )
    build_date: Optional[str] = Field(
        None, json_schema_extra={"example": "2023-07-26T08:55:00+0000"}
    )
    build_tag: Optional[str] = Field(
        None,
        json_schema_extra={"example": "app-feb20c6cdbfb8d1bffd7622dd240d23b7eb8182c"},
    )
    commit_id: Optional[str] = Field(
        None, json_schema_extra={"example": "feb20c6cdbfb8d1bffd7622dd240d23b7eb8182c"}
    )
