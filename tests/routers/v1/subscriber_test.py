import structlog
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from laa_crime_application_store_app.models.subscriber_schema import Subscriber

logger = structlog.getLogger(__name__)


def test_post_subscriber_creates_new_subscriber(client: TestClient, dbsession: Session):
    response = client.post(
        "/v1/subscriber",
        headers={"Content-Type": "application/json"},
        json={
            "webhook_url": "https://example.com/webhook",
            "subscriber_type": "provider",
        },
    )
    subscriber = dbsession.query(Subscriber).first()
    assert subscriber.webhook_url == "https://example.com/webhook"
    assert subscriber.subscriber_type == "provider"
    assert response.status_code == 201


def test_post_subscriber_avoids_duplicates(
    client: TestClient, dbsession: Session, seed_subscriber
):
    response = client.post(
        "/v1/subscriber",
        headers={"Content-Type": "application/json"},
        json={
            "webhook_url": seed_subscriber.webhook_url,
            "subscriber_type": seed_subscriber.subscriber_type,
        },
    )
    assert dbsession.query(Subscriber).count() == 1
    assert response.status_code == 204


def test_delete_subscriber_removes_record(
    client: TestClient, dbsession: Session, seed_subscriber
):
    response = client.request(
        "DELETE",
        "/v1/subscriber",
        headers={"Content-Type": "application/json"},
        json={
            "webhook_url": seed_subscriber.webhook_url,
            "subscriber_type": seed_subscriber.subscriber_type,
        },
    )
    assert dbsession.query(Subscriber).count() == 0
    assert response.status_code == 204


def test_delete_subscriber_fails_gracefully(client: TestClient, dbsession: Session):
    response = client.request(
        "DELETE",
        "/v1/subscriber",
        headers={"Content-Type": "application/json"},
        json={
            "webhook_url": "https://example.com/webhook",
            "subscriber_type": "provider",
        },
    )
    assert response.status_code == 404
