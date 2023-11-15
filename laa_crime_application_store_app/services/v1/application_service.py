from datetime import datetime
from uuid import UUID

import structlog
from sqlalchemy.orm import Session

from laa_crime_application_store_app.models.application_schema import Application
from laa_crime_application_store_app.models.application_version_schema import (
    ApplicationVersion,
)
from laa_crime_application_store_app.schema.application import Application as App
from laa_crime_application_store_app.schema.basic_application import (
    ApplicationResponse,
    BasicApplication,
)

logger = structlog.getLogger(__name__)


class ApplicationService:
    @staticmethod
    def get_application(db: Session, app_id: UUID):
        application = db.query(Application).filter(Application.id == app_id).first()

        if application is None:
            logger.info("APPLICATION_NOT_FOUND", application_id=app_id)
            return None

        application_version = (
            db.query(ApplicationVersion)
            .filter(
                ApplicationVersion.application_id == app_id,
                ApplicationVersion.version == application.current_version,
            )
            .first()
        )

        if application_version is None:
            logger.info(
                "APPLICATION_VERSION_NOT_FOUND",
                application_id=app_id,
                version=application.current_version,
            )
            return None

        return App(
            application_id=app_id,
            version=application_version.version,
            json_schema_version=application_version.json_schema_version,
            application_state=application.application_state,
            application_risk=application.application_risk,
            events=application.events or [],
            application_type=application.application_type,
            application=application_version.application,
        )

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
