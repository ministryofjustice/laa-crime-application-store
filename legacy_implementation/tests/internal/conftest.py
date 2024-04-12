import httpx
import pytest
import respx
from httpx import Response


@pytest.fixture(scope="function")
def mock_post_metadata_success():
    with respx.mock(
        base_url="https://test-url/", assert_all_called=False
    ) as respx_mock:
        put_route = respx_mock.put(
            "/application_versions/ed69ce3a-4740-11ee-9953-a259c5ffac49",
            name="get_endpoint",
        )
        put_route.return_value = Response(201, json=[])

        yield respx_mock


@pytest.fixture(scope="function")
def mock_post_metadata_failure():
    with respx.mock(
        base_url="https://test-url/", assert_all_called=False
    ) as respx_mock:
        put_route = respx_mock.put(
            "/application_versions/ed69ce3a-4740-11ee-9953-a259c5ffac49",
            name="get_endpoint",
        )
        put_route.return_value = Response(500, json=[])

        yield respx_mock


@pytest.fixture(scope="function")
def mock_post_metadata_error():
    with respx.mock(
        base_url="https://test-url/", assert_all_called=False
    ) as respx_mock:
        put_route = respx_mock.put(
            "/application_versions/ed69ce3a-4740-11ee-9953-a259c5ffac49",
            name="get_endpoint",
        )
        put_route.mock(side_effect=httpx.ConnectError)

        yield respx_mock
