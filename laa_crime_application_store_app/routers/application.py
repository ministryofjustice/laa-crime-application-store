from uuid import UUID

import structlog
from fastapi import APIRouter, Depends
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session
from starlette.responses import Response

from laa_crime_application_store_app.data.database import get_db
from laa_crime_application_store_app.models.application import Application as App
from laa_crime_application_store_app.models.application_new import ApplicationNew
from laa_crime_application_store_app.schema.application_schema import Application
from laa_crime_application_store_app.schema.application_version_schema import (
    ApplicationVersion,
)

router = APIRouter()
logger = structlog.getLogger(__name__)

responses = {
    201: {"description": "Application has been created"},
    400: {"description": "Resource not found"},
    409: {"description": "Resource already exists"},
}


@router.get("/application/{app_id}", response_model=App)
async def get_application(app_id: UUID | None = None, db: Session = Depends(get_db)):
    logger.info("GETTING_APPLICATION", application_id=app_id)
    application = db.query(Application).filter(Application.id == app_id).first()
    if application is None:
        logger.info("APPLICATION_NOT_FOUND", application_id=app_id)
        return Response(status_code=400)

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
        return Response(status_code=400)

    logger.info("APPLICATION_FOUND", application_id=app_id)
    return App(
        application_id=app_id,
        version=application_version.version,
        json_schema_version=application_version.json_schema_version,
        application_state=application.application_state,
        application_risk=application.application_risk,
        application=application_version.application,
    )


@router.post("/application/", status_code=201, responses=responses)
async def post_application(request: ApplicationNew, db: Session = Depends(get_db)):
    new_application = Application(
        id=request.application_id,
        current_version=1,
        application_state=request.application_state,
        application_risk=request.application_risk,
    )
    new_application_version = ApplicationVersion(
        application_id=request.application_id,
        version=1,
        json_schema_version=request.json_schema_version,
        application=request.application,
    )

    try:
        nested = db.begin_nested()  # establish a savepoint
        db.add_all([new_application, new_application_version])
        db.commit()
    except IntegrityError as e:
        print(f"Data Error: {e.orig}")
        nested.rollback()
        return Response(status_code=409)
    return Response(status_code=201)
