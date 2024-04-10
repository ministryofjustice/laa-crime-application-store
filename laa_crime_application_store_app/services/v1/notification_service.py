from uuid import UUID

import structlog
from sqlalchemy.orm import Session

from laa_crime_application_store_app.models.queued_job_schema import QueuedJob
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
            .with_for_update()  # Lock this record so it's definitely still available when we try to delete it
            .first()
        )
        if existing_subscriber is None:
            return False

        db.delete(existing_subscriber)
        db.commit()

        return True

    @staticmethod
    def notify(db: Session, app_id: UUID):
        # TODO: When we have roles, filter out subscribers with the same role
        subscribers = db.query(Subscriber)
        for subscriber in subscribers:
            job = QueuedJob(
                job_class="NotifySubscriberJob",
                args=[subscriber.webhook_url, str(app_id)],
            )
            db.add(job)

        db.commit()
