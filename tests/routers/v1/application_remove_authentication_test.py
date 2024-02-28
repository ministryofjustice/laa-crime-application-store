import pytest
from fastapi.testclient import TestClient

from laa_crime_application_store_app.services.auth_service import (
    CrimeSingleTenantAzureAuthorizationCodeBearer,
)


@pytest.fixture
def mock_azure_service_authenticated():
    from laa_crime_application_store_app.config.auth_settings import get_auth_settings

    mock_settings = get_auth_settings()
    mock_settings.authentication_required = "True"
    return CrimeSingleTenantAzureAuthorizationCodeBearer(
        app_client_id=mock_settings.app_client_id,
        tenant_id=mock_settings.tenant_id,
        scopes=mock_settings.scopes,
    )


@pytest.fixture
def authenticated_client(mock_azure_service_authenticated):
    from laa_crime_application_store_app.main import (
        create_app,  # Import only after env created
    )

    app = create_app(mock_azure_service_authenticated)
    with TestClient(app) as c:
        yield c


def test_application_route_returns_401_when_authentication_required(
    authenticated_client,
):
    response = authenticated_client.get("/v1/applications")
    assert response.status_code == 401


@pytest.fixture
def mock_azure_service_unauthenticated():
    from laa_crime_application_store_app.config.auth_settings import get_auth_settings

    mock_settings = get_auth_settings()
    mock_settings.authentication_required = "False"
    return CrimeSingleTenantAzureAuthorizationCodeBearer(
        app_client_id=mock_settings.app_client_id,
        tenant_id=mock_settings.tenant_id,
        scopes=mock_settings.scopes,
    )


@pytest.fixture
def unauthenticated_client(mock_azure_service_unauthenticated):
    from laa_crime_application_store_app.main import (
        create_app,  # Import only after env created
    )

    mock_azure = mock_azure_service_unauthenticated
    app = create_app(mock_azure)
    with TestClient(app) as c:
        yield c


def test_application_route_returns_200_unauthenticated(unauthenticated_client):
    response = unauthenticated_client.get("/v1/applications")
    assert response.status_code == 200
