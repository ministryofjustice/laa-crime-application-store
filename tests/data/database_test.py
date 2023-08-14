import os

from laa_crime_application_store_app.data.database import get_db


def test_get_db_returns_valid_session():
    os.environ["POSTGRES_NAME"] = "laa_crime_application_store_test"
    db_session = next(get_db())
    assert db_session.is_active is True
