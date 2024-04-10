from typing import List, Optional

import structlog
from fastapi import Depends
from fastapi.security import SecurityScopes
from fastapi_azure_auth import SingleTenantAzureAuthorizationCodeBearer
from fastapi_azure_auth.exceptions import InvalidAuth
from fastapi_azure_auth.user import User
from sentry_sdk import capture_message
from starlette.requests import Request

from laa_crime_application_store_app.config.auth_settings import get_auth_settings
from laa_crime_application_store_app.config.feature_flag_settings import (
    get_feature_flag_settings,
)
from laa_crime_application_store_app.config.permission_settings import get_permissions
from laa_crime_application_store_app.models.application_schema import Application

logger = structlog.getLogger(__name__)

settings = get_auth_settings()

permissins = get_permissions()

feature_flags = get_feature_flag_settings()


# override the call to this class to enable removal of authentication for local development
class CrimeSingleTenantAzureAuthorizationCodeBearer(
    SingleTenantAzureAuthorizationCodeBearer
):
    async def __call__(
        self, request: Request, security_scopes: SecurityScopes
    ) -> Optional[User]:
        if settings.x.lower() != "true":
            return None
        await super().__call__(request, security_scopes)


azure_schema = CrimeSingleTenantAzureAuthorizationCodeBearer(
    app_client_id=settings.app_client_id,
    tenant_id=settings.tenant_id,
    scopes=settings.scopes,
)


def current_user_roles(user: User = Depends(azure_schema)) -> Optional[str]:
    if settings.authentication_required.lower() == "true":
        # return the roles here
        if not feature_flags.roles_enabled.lower() == "true":
            # remove this branch once roles have been implemented
            # on Azure accounts
            capture_message("feature flag not enabled")
            logger.info("feature flag not enabled")
            return ["Caseworker", "Provider"]
        if user.roles:
            logger.info("we have user roles")
            return user.roles
        else:
            logger.info("no roles setup for permission logic")
            raise InvalidAuth("Roles not set-up")
    else:
        return ["authentication_not_required"]


def validate_can_create(create_user_roles: List[str] = current_user_roles()) -> None:
    logger.info("create_user_roles currently set to:{0}".format(create_user_roles))
    if "authentication_not_required" in create_user_roles:
        capture_message("No roles setup for permission logic")
        # remove this branch once roles have been implemented
        # on Azure accounts
        return None
    if permissins.provider_role not in create_user_roles:
        raise InvalidAuth("User not permitted to create application")


def validate_can_update(
    application: Application, update_user_roles: List[str] = current_user_roles()
) -> None:
    logger.info("update_user_roles currently set to:{0}".format(update_user_roles))
    if application.application_state in permissins.locked:
        raise InvalidAuth("Application in locked state")
    if "authentication_not_required" in update_user_roles:
        logger.info("VALIDATE_CAN_UPDATE client unauthenticated: Can access all roles")
        capture_message(
            "VALIDATE_CAN_UPDATE client unauthenticated: Can access all roles"
        )
        return None
    if application.application_state in permissins.all_editable:
        if (
            permissins.casework_role not in update_user_roles
            and permissins.provider_role not in update_user_roles
        ):
            raise InvalidAuth(
                "Application not permitted to update application - all roles"
            )
    if application.application_state in permissins.casework_editable:
        if permissins.casework_role not in update_user_roles:
            raise InvalidAuth(
                "Application not permitted to update application as caseworker"
            )
    if application.application_state in permissins.provider_editable:
        if permissins.provider_role not in update_user_roles:
            raise InvalidAuth(
                "Application not permitted to update application as provider"
            )

    # fallback for unknown state raise an error so state list can be updated
    capture_message(
        f"Unknown state {application.application_state} when check permission logic"
    )
