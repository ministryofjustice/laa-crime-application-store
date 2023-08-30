import pytest
import respx
from httpx import Response

from laa_crime_application_store_app.config.external_server_settings import (
    ServerSettings,
)


@pytest.fixture(scope="function")
def mock_post_metadata_success():
    with respx.mock(
        base_url="https://test-url/", assert_all_called=False
    ) as respx_mock:
        put_route = respx_mock.put(
            f"/application_versions/ed69ce3a-4740-11ee-9953-a259c5ffac49",
            name="get_endpoint",
        )
        put_route.return_value = Response(201, json=[])

        yield respx_mock


@pytest.fixture()
def external_settings():
    return ServerSettings(auth_id="12345", url="https://test-url/")
