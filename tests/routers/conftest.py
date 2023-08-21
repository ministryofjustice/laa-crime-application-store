import os
import uuid

import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import Session
from starlette.testclient import TestClient

from laa_crime_application_store_app.data.database import Base, get_db
from laa_crime_application_store_app.main import app
from laa_crime_application_store_app.schema.application_schema import Application
from laa_crime_application_store_app.schema.application_version_schema import (
    ApplicationVersion,
)

postgres_test_url = "postgresql+psycopg2://{}:{}@{}/{}".format(
    os.getenv("POSTGRES_USERNAME", "test"),
    os.getenv("POSTGRES_PASSWORD", "pass"),
    os.getenv("POSTGRES_HOSTNAME", "localhost"),
    "{}_{}".format(os.getenv("POSTGRES_NAME"), "test"),
)


@pytest.fixture(scope="session")
def engine():
    return create_engine(postgres_test_url)


@pytest.fixture
def tables(engine):
    Base.metadata.create_all(engine)


@pytest.fixture(scope="function")
def dbsession(engine, tables):
    connection = engine.connect()

    # begin a non-ORM transaction
    transaction = connection.begin()

    # bind an individual Session to the connection
    db = Session(bind=connection)

    yield db

    transaction.rollback()
    connection.close()


@pytest.fixture(scope="function")
def client(dbsession):
    app.dependency_overrides[get_db] = lambda: dbsession

    with TestClient(app) as test_client:
        yield test_client


@pytest.fixture
def seed_application(dbsession):
    app_id = uuid.uuid4()
    application = Application(
        id=app_id,
        current_version=1,
        application_state="submitted",
        application_risk="low",
    )
    version = ApplicationVersion(
        application_id=app_id,
        version=1,
        json_schema_version=1,
        application={"id": 1},
    )
    dbsession.add_all([application, version])
    dbsession.commit()
    return app_id
