import uuid
from datetime import datetime

import pytest
from fastapi_azure_auth.exceptions import InvalidAuth

from laa_crime_application_store_app.models.application_schema import Application
from laa_crime_application_store_app.services.permissions import (
    validate_can_create,
    validate_can_update,
)


def test_can_create_when_no_roles(normal_user):
    normal_user.roles = []
    assert validate_can_create(normal_user) is None


def test_can_create_when_caseworker_role(normal_user):
    normal_user.roles = ["Caseworker"]
    with pytest.raises(InvalidAuth) as e:
        assert validate_can_create(normal_user)
    assert str(e.value) == "401: User not permitted to create application"


def test_can_create_when_provider_role(normal_user):
    normal_user.roles = ["Provider"]
    assert validate_can_create(normal_user) is None


def test_can_update_when_no_roles(normal_user):
    application = Application(application_state="submitted")
    normal_user.roles = []
    assert validate_can_update(application, normal_user) is None


def test_can_update_when_locked_state(normal_user):
    application = Application(application_state="granted")
    normal_user.roles = []
    with pytest.raises(InvalidAuth) as e:
        assert validate_can_update(application, normal_user)
    assert str(e.value) == "401: Application in locked state"


def test_can_update_when_submitted_and_caseworker_role(normal_user):
    app_id = uuid.uuid4()
    application = Application(
        id=app_id,
        current_version=2,
        application_state="submitted",
        application_risk="low",
        application_type="crm7",
        updated_at=datetime.fromtimestamp(1699443712),
    )
    normal_user.roles = ["Caseworker"]
    assert validate_can_update(application, normal_user) is None


def test_can_update_when_submitted_and_provider_role(normal_user):
    application = Application(application_state="submitted")
    normal_user.roles = ["Provider"]
    with pytest.raises(InvalidAuth) as e:
        assert validate_can_update(application, normal_user)
    assert str(e.value) == "401: User not permitted to update application"


def test_can_update_when_not_submitted_and_caseworker_role(normal_user):
    application = Application(application_state="sent_back")
    normal_user.roles = ["Caseworker"]
    with pytest.raises(InvalidAuth) as e:
        assert validate_can_update(application, normal_user)
    assert str(e.value) == "401: User not permitted to update application"


def test_can_update_when_not_submitted_and_provider_role(normal_user):
    application = Application(application_state="sent_back")
    normal_user.roles = ["Provider"]
    assert validate_can_update(application, normal_user) is None


def test_can_update_when_roles_and_unknown_state(normal_user):
    application = Application(application_state="fancy")
    normal_user.roles = ["Provider"]
    assert validate_can_update(application, normal_user) is None
