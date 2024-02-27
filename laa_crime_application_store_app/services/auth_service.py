from typing import Optional

from fastapi.security import SecurityScopes
from fastapi_azure_auth import SingleTenantAzureAuthorizationCodeBearer
from fastapi_azure_auth.user import User
from starlette.requests import Request

from laa_crime_application_store_app.config.auth_settings import get_auth_settings

settings = get_auth_settings()


# override the call to this class to enable removal of authentication for local development
class CrimeSingleTenantAzureAuthorizationCodeBearer(
    SingleTenantAzureAuthorizationCodeBearer
):
    async def __call__(
        self, request: Request, security_scopes: SecurityScopes
    ) -> Optional[User]:
        if settings.authentication_required.lower() != "true":
            print(settings.authentication_required.lower())
            print("not")
            return None
        print("yes")
        await super().__call__(request, security_scopes)


def azure_auth_service():
    return CrimeSingleTenantAzureAuthorizationCodeBearer(
        app_client_id=settings.app_client_id,
        tenant_id=settings.tenant_id,
        scopes=settings.scopes,
    )
