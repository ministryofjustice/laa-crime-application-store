import uuid

import structlog
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from laa_crime_application_store_app.schema.application_schema import Application
from laa_crime_application_store_app.schema.application_version_schema import (
    ApplicationVersion,
)

logger = structlog.getLogger(__name__)


def test_no_data_returns_400(client: TestClient):
    response = client.get("/application/94ae7aab-6bd0-4c88-9d9a-9b82859293a4")
    assert response.status_code == 400


def test_no_version_data_returns_400(client: TestClient, dbsession: Session):
    app_id = uuid.uuid4()
    application = Application(
        id=app_id,
        current_version=1,
        application_state="submitted",
        application_risk="low",
    )
    dbsession.add(application)
    dbsession.commit()

    response = client.get(f"/application/{app_id}")
    assert response.status_code == 400


def test_data_returns_200(client: TestClient, seed_application):
    response = client.get(f"/application/{seed_application}")
    assert response.status_code == 200


def test_post_application_returns_200(client: TestClient, dbsession: Session):
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
    assert dbsession.query(Application).count() == 1


def test_post_application_returns_duplicate_error_if_id_already_exists(
    client: TestClient, dbsession: Session, seed_application
):
    response = client.post(
        "/application/",
        headers={"X-Token": "coneofsilence", "Content-Type": "application/json"},
        json={
            "application_id": str(seed_application),
            "json_schema_version": 1,
            "application_state": "submitted",
            "application_risk": "high",
            "application": {"id": 10},
        },
    )

    assert dbsession.query(Application).count() == 1
    assert response.status_code == 409


def test_put_application_returns_200(
    client: TestClient, dbsession: Session, seed_application
):
    response = client.put(
        f"/application/{seed_application}",
        headers={"X-Token": "coneofsilence", "Content-Type": "application/json"},
        json={
            "application_id": str(seed_application),
            "json_schema_version": 1,
            "application_state": "submitted",
            "application": {"id": 10},
        },
    )

    assert dbsession.query(Application).count() == 1
    assert response.status_code == 201


def test_put_application_create_a_new_version(
    client: TestClient, dbsession: Session, seed_application
):
    client.put(
        f"/application/{seed_application}",
        headers={"X-Token": "coneofsilence", "Content-Type": "application/json"},
        json={
            "application_id": str(seed_application),
            "json_schema_version": 1,
            "application_state": "submitted",
            "application": {"id": 10, "plea": "guilty"},
        },
    )
    assert dbsession.query(ApplicationVersion).count() == 2
    latest_version = dbsession.query(ApplicationVersion).filter_by(version=2).first()
    assert latest_version.application == {"id": 10, "plea": "guilty"}


def test_put_application_returns_400_when_application_doesnt_exist(
    client: TestClient, dbsession: Session
):
    response = client.put(
        "/application/d7f509e8-309c-4262-a41d-ebbb44deab9e",
        headers={"X-Token": "coneofsilence", "Content-Type": "application/json"},
        json={
            "application_id": "d7f509e8-309c-4262-a41d-ebbb44deab9e",
            "json_schema_version": 1,
            "application_state": "submitted",
            "application": {"id": 10},
        },
    )

    assert dbsession.query(Application).count() == 0
    assert response.status_code == 400


def test_put_application_returns_409_when_invalid_data(
    client: TestClient, dbsession: Session, seed_application
):
    response = client.put(
        f"/application/{seed_application}",
        headers={"X-Token": "coneofsilence", "Content-Type": "application/json"},
        json={
            "application_id": "d7f509e8-309c-4262-a41d-ebbb44deab9e",
            "json_schema_version": None,
            "application_state": "submitted",
            "application": {"id": 10},
        },
    )

    assert dbsession.query(ApplicationVersion).count() == 1
    assert response.status_code == 409


def test_put_application_has_no_effect_if_data_is_unchnaged(
    client: TestClient, dbsession: Session, seed_application
):
    response = client.put(
        f"/application/{seed_application}",
        headers={"X-Token": "coneofsilence", "Content-Type": "application/json"},
        json={
            "application_id": "d7f509e8-309c-4262-a41d-ebbb44deab9e",
            "json_schema_version": 1,
            "application_state": "submitted",
            "application": {"id": 1},
        },
    )

    assert dbsession.query(ApplicationVersion).count() == 1
    assert response.status_code == 200


def test_put_application_can_update_state(
    client: TestClient, dbsession: Session, seed_application
):
    client.put(
        f"/application/{seed_application}",
        headers={"X-Token": "coneofsilence", "Content-Type": "application/json"},
        json={
            "application_id": str(seed_application),
            "json_schema_version": 1,
            "application_state": "approved",
            "application": {"id": 10},
        },
    )

    assert dbsession.query(Application).count() == 1
    application = dbsession.query(Application).filter_by(id=seed_application).first()
    assert application.application_state == "approved"
