import structlog
from fastapi import Depends
from fastapi_azure_auth.exceptions import InvalidAuth
from fastapi_azure_auth.user import User
from sentry_sdk import capture_message

from laa_crime_application_store_app.models.application_schema import Application
from laa_crime_application_store_app.services.auth_service import azure_schema

logger = structlog.getLogger(__name__)

# TODO: move these into settings
LOCKED_STATES = ("granted", "expired", "auto_grant")
CASEWORKER_EDITABLE_STATES = ("submitted", "provider_updated")
PROVIDER_EDITABLE_STATES = ("part_granted", "rejected", "part_grant", "sent_back")

CASEWORKER_ROLE = "Caseworker"
PROVIDER_ROLE = "Provider"


def validate_can_create(user: User = Depends(azure_schema)) -> None:
    if user is None or not user.roles:
        capture_message("No roles setup for permission logic")
        # TODO: remove this branch once roles have been implemented
        # on Azure accounts
    elif PROVIDER_ROLE not in user.roles:
        raise InvalidAuth("User not permitted to create application")


def validate_can_update(
    application: Application, user: User = Depends(azure_schema)
) -> None:
    if application.application_state in LOCKED_STATES:
        raise InvalidAuth("Application in locked state")
    elif not user.roles:
        # TODO: remove this branch once roles have been implemented
        # on Azure accounts
        capture_message("no roles setup for permission logic")
    elif application.application_state in CASEWORKER_EDITABLE_STATES:
        if CASEWORKER_ROLE not in user.roles:
            raise InvalidAuth("User not permitted to update application")
    elif application.application_state in PROVIDER_EDITABLE_STATES:
        if PROVIDER_ROLE not in user.roles:
            raise InvalidAuth("User not permitted to update application")

    # fallback for unknown state raise an error so state list can be updated
    capture_message(
        f"Unknown state {application.application_state} when check permission logic"
    )
