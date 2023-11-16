from typing import Optional

from pydantic import Field

from laa_crime_application_store_app.schema.application_new import ApplicationNew


class ApplicationUpdate(ApplicationNew):
    updated_application_risk: Optional[str] = Field(None)
