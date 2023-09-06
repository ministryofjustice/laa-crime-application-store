from pydantic import BaseModel

from laa_crime_application_store_app.models.application_metadata import (
    ApplicationMetadata,
)


class ApplicationPostRequest(BaseModel):
    application: ApplicationMetadata | None
