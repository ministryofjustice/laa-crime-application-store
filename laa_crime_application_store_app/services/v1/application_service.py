from datetime import datetime
from uuid import UUID

import structlog
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from laa_crime_application_store_app.models.application_schema import Application
from laa_crime_application_store_app.models.application_version_schema import (
    ApplicationVersion,
)
from laa_crime_application_store_app.schema.application import Application as App
from laa_crime_application_store_app.schema.application_new import ApplicationNew
from laa_crime_application_store_app.schema.application_update import ApplicationUpdate
from laa_crime_application_store_app.schema.basic_application import (
    ApplicationResponse,
    BasicApplication,
)

logger = structlog.getLogger(__name__)


class ApplicationService:
    @staticmethod
    def get_application(db: Session, app_id: UUID):
        application = ApplicationService.__get_application_by_id(db, app_id)

        if application is None:
            logger.info("APPLICATION_NOT_FOUND", application_id=app_id)
            return None

        application_version = ApplicationService.__get_application_version(
            db, app_id, application.current_version
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

    @staticmethod
    def create_new_application(db: Session, application: ApplicationNew):
        new_application = Application(
            id=application.application_id,
            current_version=1,
            application_state=application.application_state,
            application_risk=application.application_risk,
            events=application.events,
            application_type=application.application_type,
            updated_at=datetime.now(),
        )
        new_application_version = ApplicationVersion(
            application_id=application.application_id,
            version=1,
            json_schema_version=application.json_schema_version,
            application=application.application,
        )
        nested = db.begin_nested()  # establish a savepoint

        try:
            db.add_all([new_application, new_application_version])
            db.commit()

            return new_application.id
        except IntegrityError as e:
            logger.info("DATA_ERROR_CREATING_APPLICATION", error=e.orig)
            nested.rollback()

            return None

    @staticmethod
    def update_existing_application(
        db: Session, app_id: UUID, application: ApplicationUpdate
    ):
        existing_application = ApplicationService.__get_application_by_id(db, app_id)

        if existing_application is None:
            return ApplicationService.create_new_application(db, application)

        existing_application_version = ApplicationService.__get_application_version(
            db, app_id, existing_application.current_version
        )

        logger.info("CHECKING APPLICATION CHANGES")
        logger.info(
            "CURRENT APPLICATION STATE: ", existing_application.application_state
        )
        logger.info("NEW APPLICATION STATE: ", application.application_state)
        logger.info("CURRENT APPLICATION RISK: ", existing_application.application_risk)
        logger.info("NEW APPLICATION RISK: ", application.application_risk)
        if (
            existing_application_version.application == application.application
            and existing_application.application_state == application.application_state
            and application.updated_application_risk
            in [None, existing_application.application_risk]
        ):
            return existing_application.id

        existing_application.updated_at = datetime.now()
        existing_application.current_version += 1
        existing_application.application_state = application.application_state
        existing_application.events = application.events
        logger.info("UPDATED APPLICATION: ")
        logger.info(
            "CURRENT APPLICATION STATE: ", existing_application.application_state
        )
        logger.info("NEW APPLICATION STATE: ", application.application_state)
        logger.info("CURRENT APPLICATION RISK: ", existing_application.application_risk)
        logger.info("NEW APPLICATION RISK: ", application.application_risk)

        if application.updated_application_risk is not None:
            existing_application.application_risk = application.updated_application_risk

        new_application_version = ApplicationVersion(
            application_id=application.application_id,
            version=existing_application.current_version,
            json_schema_version=application.json_schema_version,
            application=application.application,
        )

        nested = db.begin_nested()

        try:
            logger.info("PEFORMING DB TRANSACTIONS")
            db.add_all([existing_application, new_application_version])
            db.commit()
            return existing_application.id
        except IntegrityError as e:
            logger.info("DATA_ERROR_UPDATING_APPLICATION", error=e.orig)
            nested.rollback()
            return None

    @staticmethod
    def __get_application_by_id(db: Session, app_id: UUID):
        return db.query(Application).filter(Application.id == app_id).first()

    @staticmethod
    def __get_application_version(db: Session, app_id: UUID, version: int):
        return (
            db.query(ApplicationVersion)
            .filter(
                ApplicationVersion.application_id == app_id,
                ApplicationVersion.version == version,
            )
            .first()
        )
