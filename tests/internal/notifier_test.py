from unittest.mock import Mock, PropertyMock, patch

from laa_crime_application_store_app.internal.notifier import Notifier
from laa_crime_application_store_app.schema.application_schema import Application


@patch(
    "laa_crime_application_store_app.config.external_server_settings.NsmCaseworkerServerSettings",
    new_callable=Mock,
)
async def test_will_notify_via_http(
    mock_settings, mock_post_metadata_success, external_settings
):
    application = Application(
        id="ed69ce3a-4740-11ee-9953-a259c5ffac49",
        application_state="submitted",
        application_risk="high",
        current_version=1,
    )
    mock_settings.return_value = external_settings
    response = await Notifier().notify(application=application)

    assert response.status_code == 201
