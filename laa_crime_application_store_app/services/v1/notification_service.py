from uuid import UUID

import httpx
import structlog
from fastapi import Request
from sqlalchemy.orm import Session

from laa_crime_application_store_app.models.subscriber_schema import Subscriber

logger = structlog.getLogger(__name__)


class NotificationService:
    @staticmethod
    def subscribe(db: Session, subscriber_type: str, webhook_url: str):
        existing_subscriber = (
            db.query(Subscriber).filter(Subscriber.webhook_url == webhook_url).first()
        )
        if existing_subscriber is not None:
            return None

        new_subscriber = Subscriber(
            subscriber_type=subscriber_type,
            webhook_url=webhook_url,
        )
        db.add(new_subscriber)
        db.commit()

        return new_subscriber

    @staticmethod
    def unsubscribe(db: Session, subscriber_type: str, webhook_url: str):
        existing_subscriber = (
            db.query(Subscriber)
            .filter(
                Subscriber.webhook_url == webhook_url,
                Subscriber.subscriber_type == subscriber_type,
            )
            .with_for_update()
            .first()
        )
        if existing_subscriber is None:
            return False

        db.delete(existing_subscriber)
        db.commit()

        return True

    @staticmethod
    def notify(db: Session, request: Request, app_id: UUID):
        # TODO: When we have roles, filter out subscribers with the same role
        subscribers = db.query(Subscriber)
        # TODO: Run this method via Celery to allow for retrying on failure
        for subscriber in subscribers:
            NotificationService.__notify_subscriber(
                subscriber, app_id, request.headers.get("authorization")
            )

    @staticmethod
    def __notify_subscriber(subscriber: Subscriber, app_id: UUID, auth_header: str):
        headers = {"authorization": auth_header} if auth_header else {}
        httpx.post(
            subscriber.webhook_url, data={"submission_id": app_id}, headers=headers
        )
