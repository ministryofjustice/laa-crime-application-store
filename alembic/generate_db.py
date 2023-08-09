import contextlib
import os

from sqlalchemy import create_engine, exc, text

from alembic import command
from alembic.config import Config


def get_postgres_url(username, password, hostname, db):
    return "postgresql+psycopg2://{}:{}@{}/{}".format(username, password, hostname, db)


# Connect to default DB and create our database
postgres_url = get_postgres_url(
    os.getenv("POSTGRES_USERNAME", "test"),
    os.getenv("POSTGRES_PASSWORD", "pass"),
    os.getenv("POSTGRES_HOSTNAME", "localhost"),
    "postgres",
)

engine = create_engine(postgres_url)
db_name = os.getenv("POSTGRES_NAME", "laa_crime_application_store")

with contextlib.suppress(exc.ProgrammingError):
    with engine.connect() as conn:
        conn.execute(text("commit"))
        conn.execute(text("CREATE DATABASE {}".format(db_name)))

# Connect to new DB and run our migrations
database_url = get_postgres_url(
    os.getenv("POSTGRES_USERNAME", "test"),
    os.getenv("POSTGRES_PASSWORD", "pass"),
    os.getenv("POSTGRES_HOSTNAME", "localhost"),
    db_name,
)

engine = create_engine(database_url)
connection = engine.connect()

# then, load the Alembic configuration and generate the
# version table, "stamping" it with the most recent rev:

alembic_cfg = Config(f"{os.getcwd()}/alembic.ini")
command.upgrade(alembic_cfg, "head")
