from fastapi_azure_auth import SingleTenantAzureAuthorizationCodeBearer

from laa_crime_application_store_app.config.auth_settings import get_auth_settings

settings = get_auth_settings()


def azure_auth_service():
    return SingleTenantAzureAuthorizationCodeBearer(
        app_client_id=settings.app_client_id,
        tenant_id=settings.tenant_id,
        scopes=settings.scopes,
    )
