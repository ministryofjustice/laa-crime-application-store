from fastapi.testclient import TestClient

from laa_crime_application_store_app.main import app

client = TestClient(app)


def test_main_route_returns_404_when_disabled():
    response = client.get("/")
    assert response.status_code == 404


def test_main_route_body_returns_hello_world():
    response = client.get("/")
    assert response.url.path == "/docs"
