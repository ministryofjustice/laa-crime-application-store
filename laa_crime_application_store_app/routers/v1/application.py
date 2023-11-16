from uuid import UUID

import structlog
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from starlette.responses import Response

from laa_crime_application_store_app.data.database import get_db
from laa_crime_application_store_app.schema.application import Application as App
from laa_crime_application_store_app.schema.application_new import ApplicationNew
from laa_crime_application_store_app.schema.application_update import ApplicationUpdate
from laa_crime_application_store_app.schema.basic_application import ApplicationResponse
from laa_crime_application_store_app.schema.secure_json_response import (
    SecureJsonResponse,
)
from laa_crime_application_store_app.services.v1.application_service import (
    ApplicationService,
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
    logger.info("GETTING_APPLICATIONS", since=since, count=count)
    applications = ApplicationService().get_applications(db, since, count)

    logger.info(
        "GETTING_APPLICATIONS_RETURNING", number_of_apps=len(applications.applications)
    )
    return SecureJsonResponse(applications)


@router.get("/application/{app_id}", response_model=App)
async def get_application(app_id: UUID | None = None, db: Session = Depends(get_db)):
    logger.info("GETTING_APPLICATION", application_id=app_id)
    application = ApplicationService().get_application(db, app_id)

    if application is None:
        return Response(status_code=400)

    logger.info("APPLICATION_FOUND", application_id=app_id)
    return SecureJsonResponse(application)


@router.post("/application/", status_code=201, responses=responses)
async def post_application(request: ApplicationNew, db: Session = Depends(get_db)):
    logger.info("CREATING_APPLICATION", application_id=request.application_id)
    new_application = ApplicationService().create_new_application(db, request)

    if new_application is None:
        logger.info(
            "DUPLICATE_APPLICATION_FOUND", application_id=request.application_id
        )
        return Response(status_code=409)

    logger.info("APPLICATION_CREATED", application_id=request.application_id)
    return Response(status_code=201)


@router.put("/application/{app_id}", status_code=201, responses=responses)
async def put_application(
    app_id: UUID, request: ApplicationUpdate, db: Session = Depends(get_db)
):
    logger.info("UPDATING_APPLICATION", application_id=request.application_id)
    application = ApplicationService.update_existing_application(db, app_id, request)

    if application is None:
        logger.info("ISSUE_UPDATING_APPLICATION", application_id=request.application_id)
        return Response(status_code=409)

    logger.info("APPLICATION_UPDATED", application_id=request.application_id)
    return Response(status_code=201)
