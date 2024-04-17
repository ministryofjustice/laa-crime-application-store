from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

from laa_crime_application_store_app.config.database_settings import (
    get_database_settings,
)

postgres_url = "postgresql+psycopg2://{}:{}@{}/{}".format(
    get_database_settings().postgres_username,
    get_database_settings().postgres_password,
    get_database_settings().postgres_hostname,
    get_database_settings().postgres_name,
)

engine = create_engine(postgres_url)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
