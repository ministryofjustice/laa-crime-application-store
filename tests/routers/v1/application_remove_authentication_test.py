import os

import pytest
from fastapi.testclient import TestClient


@pytest.fixture
def unauthenticated_client():
    os.environ["AUTHENTICATION_REQUIRED"] = "False"
    from laa_crime_application_store_app.main import (
        app,  # Import only after env created
    )

    yield TestClient(app)


def test_application_route_returns_200_when_disabled(unauthenticated_client):
    response = unauthenticated_client.get("/v1/applications")
    assert response.status_code == 200
