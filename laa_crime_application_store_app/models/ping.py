from typing import Optional
from pydantic import BaseModel, Field


class Ping(BaseModel):
    app_branch: Optional[str] = Field(None, example='test_branch')
    build_date: Optional[str] = Field(None, example='2023-07-26T08:55:00+0000')
    build_tag: Optional[str] = Field(None, example='app-feb20c6cdbfb8d1bffd7622dd240d23b7eb8182c')
    commit_id: Optional[str] = Field(None, example='feb20c6cdbfb8d1bffd7622dd240d23b7eb8182c')