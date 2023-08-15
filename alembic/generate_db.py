import argparse
import contextlib
import os

from sqlalchemy import create_engine, exc, text

from alembic import command
from alembic.config import Config


def get_postgres_url(username, password, hostname, db):
    return "postgresql+psycopg2://{}:{}@{}/{}".format(username, password, hostname, db)


parser = argparse.ArgumentParser(
    description="Database creation for LAA Crime Application Store",
    formatter_class=argparse.ArgumentDefaultsHelpFormatter,
)
parser.add_argument(
    "-e", "--environment", help="this is what will be appended to your DB name"
)

args = parser.parse_args()

# Connect to default DB and create our database
postgres_url = get_postgres_url(
    os.getenv("POSTGRES_USERNAME"),
    os.getenv("POSTGRES_PASSWORD"),
    os.getenv("POSTGRES_HOSTNAME"),
    "postgres",
)

engine = create_engine(postgres_url)
db_name = (
    os.getenv("POSTGRES_NAME")
    if args.environment is None
    else "{}_{}".format(os.getenv("POSTGRES_NAME"), args.environment)
)

with contextlib.suppress(exc.ProgrammingError):
    with engine.connect() as conn:
        conn.execute(text("commit"))
        conn.execute(text("CREATE DATABASE {}".format(db_name)))

# Connect to new DB and run our migrations
database_url = get_postgres_url(
    os.getenv("POSTGRES_USERNAME"),
    os.getenv("POSTGRES_PASSWORD"),
    os.getenv("POSTGRES_HOSTNAME"),
    db_name,
)

engine = create_engine(database_url)
connection = engine.connect()

# then, load the Alembic configuration and generate the
# version table, "stamping" it with the most recent rev:

alembic_cfg = Config(f"{os.getcwd()}/alembic.ini")
with engine.begin() as connection:
    alembic_cfg.attributes["connection"] = connection
    command.upgrade(alembic_cfg, "head")
