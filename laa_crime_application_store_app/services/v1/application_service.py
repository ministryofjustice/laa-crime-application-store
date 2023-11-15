from datetime import datetime

from sqlalchemy.orm import Session

from laa_crime_application_store_app.models.application_schema import Application
from laa_crime_application_store_app.schema.basic_application import (
    ApplicationResponse,
    BasicApplication,
)


class ApplicationService:
    @staticmethod
    def get_applications(db: Session, since: int | None = None, count: int | None = 20):
        applications = (
            db.query(Application)
            .filter(Application.updated_at > datetime.fromtimestamp(since or 0))
            .order_by(Application.updated_at)
            .limit(count)
        )

        application_list = map(
            BasicApplication.transform_from_application, applications
        )

        return ApplicationResponse(applications=application_list)
