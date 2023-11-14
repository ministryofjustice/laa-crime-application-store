from datetime import datetime
from uuid import UUID

import structlog
from fastapi import APIRouter, Depends
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session
from starlette.responses import Response

from laa_crime_application_store_app.data.database import get_db
from laa_crime_application_store_app.internal.notifier import Notifier
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

router = APIRouter()
logger = structlog.getLogger(__name__)

responses = {
    201: {"description": "Application/Version has been created"},
    204: {"description": "No content"},
    400: {"description": "Resource not found"},
    409: {"description": "Resource already exists"},
}


@router.get("/applications", response_model=ApplicationResponse)
async def get_applications(
    since: int | None = None, count: int | None = 20, db: Session = Depends(get_db)
):
    logger.info("GETTING_APPLICATIONS")
    applications = (
        db.query(Application)
        .filter(Application.updated_at > datetime.fromtimestamp(since or 0))
        .order_by(Application.updated_at)
        .limit(count)
    )

    def transform(application):
        return BasicApplication(
            application_id=application.id,
            version=application.current_version,
            application_state=application.application_state,
            application_risk=application.application_risk,
            application_type=application.application_type,
            updated_at=application.updated_at,
        )

    return ApplicationResponse(applications=map(transform, applications))


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
        events=application.events or [],
        application_type=application.application_type,
        application=application_version.application,
    )


@router.post("/application/", status_code=201, responses=responses)
async def post_application(request: ApplicationNew, db: Session = Depends(get_db)):
    new_application = Application(
        id=request.application_id,
        current_version=1,
        application_state=request.application_state,
        application_risk=request.application_risk,
        events=request.events,
        application_type=request.application_type,
        updated_at=datetime.now(),
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

    notifier = Notifier()
    # TODO: remove the await so that this happens as a background task
    await notifier.notify(application=new_application, scope="nsm_caseworker")

    return Response(status_code=201)


@router.put("/application/{app_id}", status_code=201, responses=responses)
async def put_application(
    app_id: UUID, request: ApplicationUpdate, db: Session = Depends(get_db)
):
    try:
        nested = db.begin_nested()  # establish a savepoint
        application = db.query(Application).filter(Application.id == app_id).first()
        if application is None:
            application = Application(
                id=request.application_id,
                current_version=1,
                application_state=request.application_state,
                application_risk=request.application_risk,
                application_type=request.application_type,
                updated_at=datetime.now(),
            )
            db.add(application)
        else:
            application.updated_at = datetime.now()

        application_version = (
            db.query(ApplicationVersion)
            .filter(
                ApplicationVersion.application_id == app_id,
                ApplicationVersion.version == application.current_version,
            )
            .first()
        )

        # we ignore the issue if no application version is found to
        # avoid the system getting into a state where new versions
        # can't be added.
        if (
            application_version
            and application_version.application == request.application
            and application.application_state == request.application_state
            and request.updated_application_risk in [None, application.application_risk]
        ):
            return Response(status_code=204)

        application.current_version += 1
        application.application_state = request.application_state
        application.events = request.events
        db.add(application)

        if request.updated_application_risk is not None:
            application.application_risk = request.updated_application_risk
        new_application_version = ApplicationVersion(
            application_id=request.application_id,
            version=application.current_version,
            json_schema_version=request.json_schema_version,
            application=request.application,
        )

        db.add(new_application_version)
        db.commit()
    except IntegrityError as e:
        print(f"Data Error: {e.orig}")
        nested.rollback()
        return Response(status_code=409)

    notifier = Notifier()
    # TODO: remove the await so that this happens as a background task
    await notifier.notify(application=application, scope="nsm_caseworker")

    return Response(status_code=201)
