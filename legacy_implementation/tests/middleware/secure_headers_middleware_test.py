from fastapi.testclient import TestClient

from laa_crime_application_store_app.main import app

client = TestClient(app)


def test_referrer_policy_returns_no_referrer():
    response = client.get("/ping")
    assert response.headers.get("referrer-policy") == "no-referrer"


def test_cache_control_returns_no_store():
    response = client.get("/ping")
    assert response.headers.get("cache-control") == "no-store"


def test_x_frame_options_returns_sameorigin():
    response = client.get("/ping")
    assert response.headers.get("x-frame-options") == "sameorigin"


def test_strict_transport_security_returns_subdomain_and_max_age():
    response = client.get("/ping")
    assert (
        response.headers.get("strict-transport-security")
        == "includeSubDomains; preload; max-age=2592000"
    )


def test_csp_returns_correct_output():
    response = client.get("/ping")
    assert (
        response.headers.get("content-security-policy")
        == "default-src 'self' login.microsoftonline.com; base-uri 'self'; img-src 'self' fastapi.tiangolo.com data:; style-src 'self' cdn.jsdelivr.net 'unsafe-inline'; script-src 'self' cdn.jsdelivr.net 'unsafe-inline'"
    )
