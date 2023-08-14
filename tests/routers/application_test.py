import structlog
from fastapi.testclient import TestClient

from laa_crime_application_store_app.config.app_settings import (
    AppSettings,
    get_app_settings,
)
from laa_crime_application_store_app.main import app
from laa_crime_application_store_app.schema.application_schema import Application
from laa_crime_application_store_app.schema.application_version_schema import ApplicationVersion

logger = structlog.getLogger(__name__)


def test_post_application_returns_200(client, db):
    response = client.post(
        "/application/",
        headers={"X-Token": "coneofsilence", "Content-Type": "application/json"},
        json={
            "application_id": "d7f509e8-309c-4262-a41d-ebbb44deab9e",
            "json_schema_version": 1,
            "application_state": "submitted",
            "application_risk": "high",
            "application": {"id": 10},
        },
    )

    assert response.status_code == 201
    assert db.query(Application).count() == 1


def test_returns_duplicate_error_if_id_already_exists(client, db):
    new_application = Application(
        id="d7f509e8-309c-4262-a41d-ebbb44deab9e",
        current_version=1,
        application_state="submitted",
        application_risk="high",
    )
    new_application_version = ApplicationVersion(
        application_id="d7f509e8-309c-4262-a41d-ebbb44deab9e",
        version=1,
        json_schema_version=1,
        application={},
    )

    db.add_all([new_application, new_application_version])
    db.commit()

    response = client.post(
        "/application/",
        headers={"X-Token": "coneofsilence", "Content-Type": "application/json"},
        json={
            "application_id": "d7f509e8-309c-4262-a41d-ebbb44deab9e",
            "json_schema_version": 1,
            "application_state": "submitted",
            "application_risk": "high",
            "application": {"id": 10},
        },
    )

    assert db.query(Application).count() == 1
    assert response.status_code == 409
