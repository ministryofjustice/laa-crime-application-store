from laa_crime_application_store_app.internal.notifier import Notifier
from laa_crime_application_store_app.schema.application_schema import Application


async def test_will_notify_via_http():
    application = Application(
        id="ed69ce3a-4740-11ee-9953-a259c5ffac49",
        application_state="submitted",
        application_risk="high",
        current_version=1,
    )
    response = await Notifier().notify(application=application)

    assert response is True
