import structlog
from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session
from starlette.responses import Response

from laa_crime_application_store_app.data.database import get_db
from laa_crime_application_store_app.decorators.auth_logging_decorator import (
    auth_logger,
)
from laa_crime_application_store_app.schema.subscriber import Subscriber
from laa_crime_application_store_app.services.v1.notification_service import (
    NotificationService,
)

router = APIRouter()
logger = structlog.getLogger(__name__)


@router.post("/subscriber")
@auth_logger
async def post_subscriber(
    request: Request,
    subscriber: Subscriber,
    db: Session = Depends(get_db),
):
    logger.info("CREATING_SUBSCRIBER")
    new_subscriber = NotificationService.subscribe(
        db, subscriber.subscriber_type, subscriber.webhook_url
    )

    if new_subscriber is not None:
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
