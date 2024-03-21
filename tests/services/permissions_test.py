import uuid
from datetime import datetime

from laa_crime_application_store_app.models.application_schema import Application
from laa_crime_application_store_app.services.permissions import get_permissions


def test_permission_when_no_roles():
    application = Application(application_state="submitted")
    roles = []
    assert get_permissions().allow_update(application, roles)


def test_permission_when_locked_state():
    application = Application(application_state="granted")
    roles = []
    assert not get_permissions().allow_update(application, roles)


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
    roles = ["caseworker"]
    assert get_permissions().allow_update(application, roles)


def test_permission_when_submitted_and_provider_role():
    application = Application(application_state="submitted")
    roles = ["provider"]
    assert not get_permissions().allow_update(application, roles)


def test_permission_when_not_submitted_and_caseworker_role():
    application = Application(application_state="sent_back")
    roles = ["caseworker"]
    assert not get_permissions().allow_update(application, roles)


def test_permission_when_not_submitted_and_provider_role():
    application = Application(application_state="sent_back")
    roles = ["provider"]
    assert get_permissions().allow_update(application, roles)
