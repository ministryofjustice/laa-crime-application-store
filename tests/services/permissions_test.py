import uuid
from datetime import datetime

from laa_crime_application_store_app.models.application_schema import Application
from laa_crime_application_store_app.services.permissions import UserWithPermissions


def test_permission_when_no_roles():
    application = Application(application_state="submitted")
    roles = []
    user = UserWithPermissions(roles=roles)
    assert user.validates_can_update(application)


def test_permission_when_locked_state():
    application = Application(application_state="granted")
    roles = []
    user = UserWithPermissions(roles=roles)
    assert not user.validates_can_update(application)


def test_permission_when_submitted_and_caseworker_role():
    app_id = uuid.uuid4()
    application = Application(
        id=app_id,
        current_version=2,
        application_state="submitted",
        application_risk="low",
        application_type="crm7",
        updated_at=datetime.fromtimestamp(1699443712),
    )
    roles = ["Caseworker"]
    user = UserWithPermissions(roles=roles)
    assert user.validates_can_update(application)


def test_permission_when_submitted_and_provider_role():
    application = Application(application_state="submitted")
    roles = ["Provider"]
    user = UserWithPermissions(roles=roles)
    assert not user.validates_can_update(application)


def test_permission_when_not_submitted_and_caseworker_role():
    application = Application(application_state="sent_back")
    roles = ["Caseworker"]
    user = UserWithPermissions(roles=roles)
    assert not user.validates_can_update(application)


def test_permission_when_not_submitted_and_provider_role():
    application = Application(application_state="sent_back")
    roles = ["Provider"]
    user = UserWithPermissions(roles=roles)
    assert user.validates_can_update(application)


def test_permission_when_roles_and_unknown_state():
    application = Application(application_state="fancy")
    roles = ["Provider"]

    user = UserWithPermissions(roles=roles)
    assert user.validates_can_update(application)
