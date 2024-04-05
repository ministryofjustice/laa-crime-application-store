from uuid import UUID

import structlog
from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session
from starlette.responses import Response

from laa_crime_application_store_app.data.database import get_db
from laa_crime_application_store_app.decorators.auth_logging_decorator import (
    auth_logger,
)
from laa_crime_application_store_app.schema.application import Application as App
from laa_crime_application_store_app.schema.application_new import ApplicationNew
from laa_crime_application_store_app.schema.application_update import ApplicationUpdate
from laa_crime_application_store_app.schema.basic_application import ApplicationResponse
from laa_crime_application_store_app.schema.subscriber import Subscriber
from laa_crime_application_store_app.services.v1.application_service import (
    ApplicationService,
)
from laa_crime_application_store_app.services.v1.notification_service import (
    NotificationService,
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
@auth_logger
async def get_applications(
    request: Request,
    since: int | None = None,
    count: int | None = 20,
    db: Session = Depends(get_db),
):
    logger.info("GETTING_APPLICATIONS", since=since, count=count)
    applications = ApplicationService().get_applications(db, since, count)

    logger.info(
        "GETTING_APPLICATIONS_RETURNING", number_of_apps=len(applications.applications)
    )
    return applications


@router.get("/application/{app_id}", response_model=App)
@auth_logger
async def get_application(
    request: Request,
    app_id: UUID | None = None,
    app_version: int | None = None,
    db: Session = Depends(get_db),
):
    logger.info("GETTING_APPLICATION", application_id=app_id)
    application = ApplicationService().get_application(db, app_id, app_version)

    if application is None:
        return Response(status_code=400)

    logger.info("APPLICATION_FOUND", application_id=app_id)

    return application


@router.post("/application/", status_code=201, responses=responses)
@auth_logger
async def post_application(
    request: Request, application: ApplicationNew, db: Session = Depends(get_db)
):
    logger.info("CREATING_APPLICATION", application_id=application.application_id)
    new_application = ApplicationService().create_new_application(db, application)

    if new_application is None:
        logger.info(
            "DUPLICATE_APPLICATION_FOUND", application_id=application.application_id
        )
        return Response(status_code=409)

    logger.info("APPLICATION_CREATED", application_id=application.application_id)
    NotificationService().notify(db, request, application.application_id)
    return Response(status_code=201)


@router.put("/application/{app_id}", status_code=201, responses=responses)
@auth_logger
async def put_application(
    request: Request,
    app_id: UUID,
    application: ApplicationUpdate,
    db: Session = Depends(get_db),
):
    logger.info("UPDATING_APPLICATION", application_id=application.application_id)
    existing_application = ApplicationService.update_existing_application(
        db, app_id, application
    )

    if existing_application is None:
        logger.info(
            "ISSUE_UPDATING_APPLICATION", application_id=application.application_id
        )
        return Response(status_code=409)

    logger.info("APPLICATION_UPDATED", application_id=application.application_id)
    NotificationService().notify(db, request, application.application_id)
    return Response(status_code=201)


@router.post("/subscriber")
@auth_logger
async def post_subscriber(
    request: Request,
    subscriber: Subscriber,
    db: Session = Depends(get_db),
):
    logger.info("CREATING_SUBSCRIBER")
    existing_subscriber = NotificationService.subscribe(
        db, subscriber.subscriber_type, subscriber.webhook_url
    )

    if existing_subscriber is None:
        logger.info("SUBSCRIBER_CREATED")
        return Response(status_code=201)
    else:
        logger.info("SUBSCRIBER_ALREADY_EXISTED")
        return Response(status_code=204)


@router.delete("/subscriber")
@auth_logger
async def delete_subscriber(
    request: Request,
    subscriber: Subscriber,
    db: Session = Depends(get_db),
):
    logger.info("DELETING_SUBSCRIBER")
    deleted = NotificationService.unsubscribe(
        db, subscriber.subscriber_type, subscriber.webhook_url
    )

    if deleted:
        logger.info("SUBSCRIBER_DELETED")
        return Response(status_code=204)
    else:
        logger.info("SUBSCRIBER_NOT_FOUND")
        return Response(status_code=404)
