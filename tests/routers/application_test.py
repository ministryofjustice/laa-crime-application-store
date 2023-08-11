import structlog
from fastapi.testclient import TestClient

from laa_crime_application_store_app.config.app_settings import (
    AppSettings,
    get_app_settings,
)
from laa_crime_application_store_app.main import app
from laa_crime_application_store_app.schema.application_schema import Application

logger = structlog.getLogger(__name__)


def test_post_application_returns_200(client, db):
    response = client.post(
        "/application/",
        headers={"X-Token": "coneofsilence", "Content-Type": "application/json"},
        json={
            "claim_id": "d7f509e8-309c-4262-a41d-ebbb44deab9e",
            "json_schema_version": 1,
            "application_state": "submitted",
            "risk": "high",
            "application": {"id": 10},
        },
    )

    assert db.query(Application).count() == 1

    logger.info("response", response=response.headers)
    assert response.status_code == 201
