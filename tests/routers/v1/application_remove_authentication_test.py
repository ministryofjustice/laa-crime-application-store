import os

import pytest
from fastapi.testclient import TestClient

from laa_crime_application_store_app.services.auth_service import (
    CrimeSingleTenantAzureAuthorizationCodeBearer,
)


async def mock_azure_service():
    app_client_id: str = ""
    tenant_id: str = ""
    scope_description: str = ".default"
    scope_name: str = f"{app_client_id}/{scope_description}"

    mock_s = {
        "authentication_required": "False",
        "app_client_id": app_client_id,
        "tenant_id": tenant_id,
        "scopes": {scope_name: scope_description},
    }

    return CrimeSingleTenantAzureAuthorizationCodeBearer(
        app_client_id=mock_s["app_client_id"],
        tenant_id=mock_s["tenant_id"],
        scopes=mock_s["scopes"],
    )


@pytest.fixture
def unauthenticated_client():
    os.environ["AUTHENTICATION_REQUIRED"] = "FALSE"
    from laa_crime_application_store_app.main import (
        create_app,  # Import only after env created
    )

    app = create_app(mock_azure_service)
    with TestClient(app) as c:
        yield c


def test_application_route_returns_200_when_authentication_disabled(
    unauthenticated_client,
):
    # just checking to see if removing authentication works
    response = unauthenticated_client.get(
        "/v1/applications", params={"since": "1699443712"}
    )
    assert response.status_code == 200


@pytest.fixture
def authenticated_client():
    os.environ["AUTHENTICATION_REQUIRED"] = "TRUE"
    from laa_crime_application_store_app.main import (
        create_app,  # Import only after env created
    )

    app = create_app(mock_azure_service)
    with TestClient(app) as c:
        yield c


def test_application_route_returns_404_when_authentication_enabled(
    authenticated_client,
):
    # just checking to see if authentication works
    response = authenticated_client.get(
        "/v1/applications", params={"since": "1699443712"}
    )
    assert response.status_code == 200
