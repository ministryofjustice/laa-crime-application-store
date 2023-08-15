import os

from laa_crime_application_store_app.data.database import get_db


def test_get_db_returns_valid_session():
    "{}_{}".format(os.getenv("POSTGRES_NAME"), "test")
    db_session = next(get_db())
    assert db_session.is_active is True
