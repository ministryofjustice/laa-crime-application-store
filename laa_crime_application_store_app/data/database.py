import os

from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

postgres_url = "postgresql+psycopg2://{}:{}@{}/{}".format(
    os.getenv("POSTGRES_USERNAME", "test"),
    os.getenv("POSTGRES_PASSWORD", "pass"),
    os.getenv("POSTGRES_HOSTNAME", "localhost"),
    os.getenv("POSTGRES_NAME", "laa_crime_application_store"),
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
