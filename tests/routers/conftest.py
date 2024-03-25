import uuid
from datetime import datetime

import pytest
from fastapi import Request
from fastapi_azure_auth.user import User
from sqlalchemy import create_engine
from sqlalchemy.orm import Session
from starlette.testclient import TestClient

from laa_crime_application_store_app.config.database_settings import (
    get_database_settings,
)
from laa_crime_application_store_app.data.database import Base, get_db
from laa_crime_application_store_app.main import app, azure_schema
from laa_crime_application_store_app.models.application_schema import Application
from laa_crime_application_store_app.models.application_version_schema import (
    ApplicationVersion,
)
from laa_crime_application_store_app.services.auth_service import (
    CrimeSingleTenantAzureAuthorizationCodeBearer,
)

postgres_test_url = "postgresql+psycopg2://{}:{}@{}/{}".format(
    get_database_settings().postgres_username,
    get_database_settings().postgres_password,
    get_database_settings().postgres_hostname,
    get_database_settings().test_database_name,
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


async def mock_normal_user(request: Request):
    user = User(
        claims={},
        preferred_username="NormalUser",
        roles=[],
        aud="aud",
        tid="tid",
        access_token="123",
        is_guest=False,
        iat=1537231048,
        nbf=1537231048,
        exp=1537234948,
        iss="iss",
        aio="aio",
        sub="sub",
        oid="oid",
        uti="uti",
        rh="rh",
        ver="2.0",
    )
    request.state.user = user
    return user


@pytest.fixture(scope="function")
def client(dbsession):
    app.dependency_overrides[get_db] = lambda: dbsession
    app.dependency_overrides[azure_schema] = mock_normal_user

    yield TestClient(app)


@pytest.fixture
def seed_application(dbsession):
    return create_application(dbsession, None)


@pytest.fixture
def seed_application_with_events(dbsession):
    return create_application(dbsession, [{"id": 11, "value": "alpha"}])


def create_application(dbsession, events):
    app_id = uuid.uuid4()
    application = Application(
        id=app_id,
        current_version=2,
        application_state="submitted",
        application_risk="low",
        application_type="crm7",
        updated_at=datetime.fromtimestamp(1699443712),
        events=events,
    )
    version = ApplicationVersion(
        application_id=app_id,
        version=1,
        json_schema_version=1,
        application={"id": 1},
    )
    version_2 = ApplicationVersion(
        application_id=app_id,
        version=2,
        json_schema_version=1,
        application={"id": 2},
    )
    dbsession.add_all([application, version, version_2])
    dbsession.commit()
    return app_id


# these fixtures are used to check the authentication settings


@pytest.fixture
def mock_azure_service_authenticated():
    from laa_crime_application_store_app.config.auth_settings import get_auth_settings

    mock_settings = get_auth_settings()
    mock_settings.authentication_required = "True"
    return CrimeSingleTenantAzureAuthorizationCodeBearer(
        app_client_id=mock_settings.app_client_id,
        tenant_id=mock_settings.tenant_id,
        scopes=mock_settings.scopes,
    )


@pytest.fixture
def mock_azure_service_unauthenticated():
    from laa_crime_application_store_app.config.auth_settings import get_auth_settings

    mock_settings = get_auth_settings()
    mock_settings.authentication_required = "False"
    return CrimeSingleTenantAzureAuthorizationCodeBearer(
        app_client_id=mock_settings.app_client_id,
        tenant_id=mock_settings.tenant_id,
        scopes=mock_settings.scopes,
    )


@pytest.fixture(scope="function")
def authenticated_client(mock_azure_service_authenticated, dbsession):
    from laa_crime_application_store_app.main import (
        create_app,  # Import only after env created
    )

    authenticated_app = create_app(mock_azure_service_authenticated)
    authenticated_app.dependency_overrides[get_db] = lambda: dbsession
    with TestClient(authenticated_app) as c:
        yield c


@pytest.fixture(scope="function")
def unauthenticated_client(mock_azure_service_unauthenticated, dbsession):
    from laa_crime_application_store_app.main import (
        create_app,  # Import only after env created
    )

    mock_azure = mock_azure_service_unauthenticated
    unauthenticated_app = create_app(mock_azure)
    unauthenticated_app.dependency_overrides[get_db] = lambda: dbsession
    with TestClient(unauthenticated_app) as c:
        yield c
