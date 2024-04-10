import uuid
from datetime import datetime

import pytest
from fastapi_azure_auth.exceptions import InvalidAuth

from laa_crime_application_store_app.models.application_schema import Application
from laa_crime_application_store_app.models.application_version_schema import (
    ApplicationVersion,
)
from laa_crime_application_store_app.services.auth_service import (
    validate_can_create,
    validate_can_update,
)


def test_can_create_when_no_roles():
    assert validate_can_create(["authentication_not_required"]) is None


def test_can_create_when_caseworker_role():
    with pytest.raises(Exception) as e:
        validate_can_create(["Caseworker"])
    assert e.type == InvalidAuth
    assert str(e.value) == "401: User not permitted to create application"


def test_can_create_when_provider_role():
    assert validate_can_create("Provider") is None


def test_can_update_when_no_roles():
    application = Application(application_state="submitted")
    assert validate_can_update(application, ["authentication_not_required"]) is None


def test_can_update_when_locked_state():
    application = Application(application_state="granted")
    with pytest.raises(Exception) as e:
        validate_can_update(application, ["authentication_not_required"])
    assert e.type == InvalidAuth
    assert str(e.value) == "401: Application in locked state"


def test_can_update_when_submitted_and_caseworker_role():
    app_id = uuid.uuid4()
    application = Application(
        id=app_id,
        current_version=2,
        application_state="submitted",
        application_risk="low",
        application_type="crm7",
        updated_at=datetime.fromtimestamp(1699443712),
    )
    assert validate_can_update(application, ["Caseworker"]) is None


def test_can_update_when_submitted_and_provider_role():
    application = Application(application_state="submitted")
    with pytest.raises(Exception) as e:
        validate_can_update(application, ["Provider"])
    assert e.type == InvalidAuth
    assert (
        str(e.value)
        == "401: Application not permitted to update application as caseworker"
    )


def test_can_update_when_not_submitted_and_caseworker_role():
    application = Application(application_state="part_grant")
    with pytest.raises(Exception) as e:
        validate_can_update(application, ["Caseworker"])
    assert e.type == InvalidAuth
    assert (
        str(e.value)
        == "401: Application not permitted to update application as provider"
    )


def test_can_update_when_not_submitted_and_provider_role():
    application = Application(application_state="part_grant")
    assert validate_can_update(application, ["Provider"]) is None


def test_can_update_when_sent_back_and_caseworker_role():
    application = Application(application_state="sent_back")
    assert validate_can_update(application, ["Caseworker"]) is None


def test_can_update_when_sent_back_and_provider_role():
    application = Application(application_state="sent_back")
    assert validate_can_update(application, ["Provider"]) is None


def test_can_update_when_sent_back_and_other_role():
    application = Application(application_state="sent_back")
    with pytest.raises(Exception) as e:
        validate_can_update(application, ["other"])
    assert e.type == InvalidAuth
    assert (
        str(e.value)
        == "401: Application not permitted to update application - all roles"
    )


def test_can_update_when_roles_and_unknown_state():
    application = Application(application_state="fancy")
    assert validate_can_update(application, ["Provider"]) is None
