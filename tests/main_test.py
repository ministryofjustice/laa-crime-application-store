from fastapi.testclient import TestClient

from laa_crime_application_store_app.main import app

client = TestClient(app)


def test_main_route_returns_200():
    response = client.get("/")
    assert response.status_code == 200


def test_main_route_body_returns_hello_world():
    response = client.get("/")
    expected_result = {"Hello": "World"}
    assert response.json() == expected_result
