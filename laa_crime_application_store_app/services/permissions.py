from fastapi import Depends
from fastapi_azure_auth.exceptions import InvalidAuth
from fastapi_azure_auth.user import User
from sentry_sdk import capture_message

from laa_crime_application_store_app.config.permission_settings import get_permissions
from laa_crime_application_store_app.models.application_schema import Application
from laa_crime_application_store_app.services.auth_service import azure_schema

permissins = get_permissions()


def validate_can_create(user: User = Depends(azure_schema)) -> None:
    if user is None or not user.roles:
        capture_message("No roles setup for permission logic")
        # TODO: remove this branch once roles have been implemented
        # on Azure accounts
    elif permissins.provider_role not in user.roles:
        raise InvalidAuth("User not permitted to create application")


def validate_can_update(
    application: Application, user: User = Depends(azure_schema)
) -> None:
    if application.application_state in permissins.locked:
        raise InvalidAuth("Application in locked state")
    elif not user.roles:
        # TODO: remove this branch once roles have been implemented
        # on Azure accounts
        capture_message("no roles setup for permission logic")
    elif application.application_state in permissins.casework_editable:
        if permissins.casework_role not in user.roles:
            raise InvalidAuth("User not permitted to update application")
    elif application.application_state in permissins.provider_editable:
        if permissins.provider_role not in user.roles:
            raise InvalidAuth("User not permitted to update application")

    # fallback for unknown state raise an error so state list can be updated
    capture_message(
        f"Unknown state {application.application_state} when check permission logic"
    )
