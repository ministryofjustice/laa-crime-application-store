import json
import uuid
from datetime import datetime, timedelta

import structlog
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from laa_crime_application_store_app.models.application_schema import Application
from laa_crime_application_store_app.models.application_version_schema import (
    ApplicationVersion,
)

logger = structlog.getLogger(__name__)


def test_applications_returns_401_when_authentication_required(authenticated_client):
    response = authenticated_client.get("/v1/applications")
    assert response.status_code == 401


def test_applications_returns_200_when_unauthenticated(unauthenticated_client):
    response = unauthenticated_client.get("/v1/applications")
    assert response.status_code == 200


def test_no_applications_return_empty_array(client: TestClient):
    response = client.get("/v1/applications")
    assert response.status_code == 200
    assert response.content == b'{"applications":[]}'


def test_applications_return_basic_info(client: TestClient, seed_application):
    seed_application
    response = client.get("/v1/applications")
    assert response.status_code == 200
    json_data = json.loads(response.content)
    assert len(json_data["applications"]) == 1
    assert json_data["applications"][0]["application_id"] == str(seed_application)


def test_no_applications_since_return_empty_array(client: TestClient, seed_application):
    seed_application
    response = client.get("/v1/applications", params={"since": "1699443712"})
    assert response.status_code == 200
    assert response.content == b'{"applications":[]}'


def test_no_data_returns_400(client: TestClient):
    response = client.get("/v1/application/94ae7aab-6bd0-4c88-9d9a-9b82859293a4")
    assert response.status_code == 400


def test_no_version_data_returns_400(client: TestClient, dbsession: Session):
    app_id = uuid.uuid4()
    application = Application(
        id=app_id,
        current_version=1,
        application_state="submitted",
        application_risk="low",
        application_type="crm7",
        updated_at=datetime.now(),
    )
    dbsession.add(application)
    dbsession.commit()

    response = client.get(f"/v1/application/{app_id}")
    assert response.status_code == 400


def test_data_returns_200(client: TestClient, seed_application):
    response = client.get(f"/v1/application/{seed_application}")
    assert response.status_code == 200


def test_data_selected_version_returns_200(client: TestClient, seed_application):
    response = client.get(
        f"/v1/application/{seed_application}", params={"app_version": 2}
    )
    assert response.status_code == 200


def test_data_selected_version_returns_400(client: TestClient, seed_application):
    response = client.get(
        f"/v1/application/{seed_application}", params={"app_version": 3}
    )
    assert response.status_code == 400


def test_post_application_returns_200(client: TestClient, dbsession: Session):
    response = client.post(
        "/v1/application/",
        headers={"X-Token": "coneofsilence", "Content-Type": "application/json"},
        json={
            "application_id": "d7f509e8-309c-4262-a41d-ebbb44deab9e",
            "json_schema_version": 1,
            "application_state": "submitted",
            "application_risk": "high",
            "application_type": "crm7",
            "application": {"id": 10},
        },
    )

    assert response.status_code == 201
    assert dbsession.query(Application).count() == 1


def test_post_application_returns_duplicate_error_if_id_already_exists(
    client: TestClient, dbsession: Session, seed_application
):
    response = client.post(
        "/v1/application/",
        headers={"X-Token": "coneofsilence", "Content-Type": "application/json"},
        json={
            "application_id": str(seed_application),
            "json_schema_version": 1,
            "application_state": "submitted",
            "application_risk": "high",
            "application_type": "crm7",
            "application": {"id": 10},
        },
    )

    assert dbsession.query(Application).count() == 1
    assert response.status_code == 409


def test_put_application_returns_200(
    client: TestClient, dbsession: Session, seed_application
):
    response = client.put(
        f"/v1/application/{seed_application}",
        headers={"X-Token": "coneofsilence", "Content-Type": "application/json"},
        json={
            "application_id": str(seed_application),
            "json_schema_version": 1,
            "application_state": "submitted",
            "application_risk": "low",
            "application_type": "crm7",
            "application": {"id": 10},
        },
    )

    assert dbsession.query(Application).count() == 1
    assert response.status_code == 201


def test_put_application_create_a_new_version(
    client: TestClient, dbsession: Session, seed_application
):
    client.put(
        f"/v1/application/{seed_application}",
        headers={"X-Token": "coneofsilence", "Content-Type": "application/json"},
        json={
            "application_id": str(seed_application),
            "json_schema_version": 1,
            "application_state": "submitted",
            "application_risk": "low",
            "application_type": "crm7",
            "application": {"id": 10, "plea": "guilty"},
        },
    )
    assert dbsession.query(ApplicationVersion).count() == 3
    application = dbsession.query(Application).filter_by(id=seed_application).first()
    latest_version = dbsession.query(ApplicationVersion).filter_by(version=3).first()
    assert latest_version.application == {"id": 10, "plea": "guilty"}
    assert (datetime.now() - application.updated_at) < timedelta(seconds=3)


def test_put_application_create_a_new_application_when_it_doesnt_exist(
    client: TestClient, dbsession: Session
):
    response = client.put(
        "/v1/application/d7f509e8-309c-4262-a41d-ebbb44deab9e",
        headers={"X-Token": "coneofsilence", "Content-Type": "application/json"},
        json={
            "application_id": "d7f509e8-309c-4262-a41d-ebbb44deab9e",
            "json_schema_version": 1,
            "application_state": "submitted",
            "application_risk": "low",
            "application_type": "crm7",
            "application": {"id": 10},
        },
    )

    assert dbsession.query(Application).count() == 1
    assert response.status_code == 201


def test_put_application_returns_409_when_invalid_data(
    client: TestClient, dbsession: Session, seed_application
):
    response = client.put(
        f"/v1/application/{seed_application}",
        headers={"X-Token": "coneofsilence", "Content-Type": "application/json"},
        json={
            "application_id": "d7f509e8-309c-4262-a41d-ebbb44deab9e",
            "json_schema_version": None,
            "application_state": "submitted",
            "application_risk": "low",
            "application_type": "crm7",
            "application": {"id": 10},
        },
    )

    assert dbsession.query(ApplicationVersion).count() == 2
    assert response.status_code == 409


def test_put_application_has_no_effect_if_data_is_unchanged(
    client: TestClient, dbsession: Session, seed_application
):
    response = client.put(
        f"/v1/application/{seed_application}",
        headers={"X-Token": "coneofsilence", "Content-Type": "application/json"},
        json={
            "application_id": "d7f509e8-309c-4262-a41d-ebbb44deab9e",
            "json_schema_version": 1,
            "application_state": "submitted",
            "application_risk": "low",
            "application_type": "crm7",
            "application": {"id": 2},
        },
    )

    assert dbsession.query(ApplicationVersion).count() == 2
    assert response.status_code == 201


def test_put_application_can_update_state(
    client: TestClient, dbsession: Session, seed_application
):
    client.put(
        f"/v1/application/{seed_application}",
        headers={"X-Token": "coneofsilence", "Content-Type": "application/json"},
        json={
            "application_id": str(seed_application),
            "json_schema_version": 1,
            "application_state": "approved",
            "application_risk": "low",
            "application_type": "crm7",
            "application": {"id": 10},
        },
    )

    assert dbsession.query(Application).count() == 1
    application = dbsession.query(Application).filter_by(id=seed_application).first()
    assert application.application_state == "approved"


def test_put_application_changes_to_application_risk_are_ignored(
    client: TestClient, dbsession: Session, seed_application
):
    client.put(
        f"/v1/application/{seed_application}",
        headers={"X-Token": "coneofsilence", "Content-Type": "application/json"},
        json={
            "application_id": str(seed_application),
            "json_schema_version": 1,
            "application_state": "approved",
            "application_risk": "high",
            "application_type": "crm7",
            "application": {"id": 10},
        },
    )

    application = dbsession.query(Application).filter_by(id=seed_application).first()
    assert application.application_risk == "low"


def test_put_application_changes_to_updated_application_risk_are_applied(
    client: TestClient, dbsession: Session, seed_application
):
    client.put(
        f"/v1/application/{seed_application}",
        headers={"X-Token": "coneofsilence", "Content-Type": "application/json"},
        json={
            "application_id": str(seed_application),
            "json_schema_version": 1,
            "application_state": "approved",
            "application_risk": "high",
            "application_type": "crm7",
            "updated_application_risk": "high",
            "application": {"id": 10},
        },
    )

    application = dbsession.query(Application).filter_by(id=seed_application).first()
    assert application.application_risk == "high"


def test_put_application_creates_new_event_records(
    client: TestClient, dbsession: Session, seed_application
):
    client.put(
        f"/v1/application/{seed_application}",
        headers={"X-Token": "coneofsilence", "Content-Type": "application/json"},
        json={
            "application_id": str(seed_application),
            "json_schema_version": 1,
            "application_state": "submitted",
            "application_risk": "low",
            "application_type": "crm7",
            "application": {"id": 10, "plea": "guilty"},
            "events": [{"id": 11, "value": "alpha"}],
        },
    )
    application = dbsession.query(Application).filter_by(id=seed_application).first()
    assert application.events == [{"id": 11, "value": "alpha"}]


def test_put_application_does_not_delete_existing_events(
    client: TestClient, dbsession: Session, seed_application_with_events
):
    client.put(
        f"/v1/application/{seed_application_with_events}",
        headers={"X-Token": "coneofsilence", "Content-Type": "application/json"},
        json={
            "application_id": str(seed_application_with_events),
            "json_schema_version": 1,
            "application_state": "submitted",
            "application_risk": "low",
            "application_type": "crm7",
            "application": {"id": 10, "plea": "guilty"},
            "events": [],
        },
    )
    application = (
        dbsession.query(Application).filter_by(id=seed_application_with_events).first()
    )
    assert application.events == [{"id": 11, "value": "alpha"}]


def test_put_application_does_not_overwrite_existing_events(
    client: TestClient, dbsession: Session, seed_application_with_events
):
    client.put(
        f"/v1/application/{seed_application_with_events}",
        headers={"X-Token": "coneofsilence", "Content-Type": "application/json"},
        json={
            "application_id": str(seed_application_with_events),
            "json_schema_version": 1,
            "application_state": "submitted",
            "application_risk": "low",
            "application_type": "crm7",
            "application": {"id": 10, "plea": "guilty"},
            "events": [{"id": 11, "value": "beta"}],
        },
    )
    application = (
        dbsession.query(Application).filter_by(id=seed_application_with_events).first()
    )
    assert application.events == [{"id": 11, "value": "alpha"}]


def test_put_application_appends_new_events(
    client: TestClient, dbsession: Session, seed_application_with_events
):
    client.put(
        f"/v1/application/{seed_application_with_events}",
        headers={"X-Token": "coneofsilence", "Content-Type": "application/json"},
        json={
            "application_id": str(seed_application_with_events),
            "json_schema_version": 1,
            "application_state": "submitted",
            "application_risk": "low",
            "application_type": "crm7",
            "application": {"id": 10, "plea": "guilty"},
            "events": [{"id": 12, "value": "beta"}],
        },
    )
    application = (
        dbsession.query(Application).filter_by(id=seed_application_with_events).first()
    )
    assert application.events == [
        {"id": 11, "value": "alpha"},
        {"id": 12, "value": "beta"},
    ]
