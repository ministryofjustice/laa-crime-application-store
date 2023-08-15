# Alembic Database Migration tool

## Getting Started

To be able to perform migrations, you will need to set some Environment Variables for the tool to connect to your DB.
This can be done by adding them to your `.env` file.

The following variables are required:
```
POSTGRES_USERNAME={database user}
POSTGRES_PASSWORD={database password}
POSTGRES_HOSTNAME={database address}
POSTGRES_NAME={database name}
```

To get up and running locally, run the generate_db script to create the DB and any pending migrations
```shell
pipenv run generate_db
```

If your database already exists it will not recreate it but should still run any pending upgrades.

To create a test database run the following command
```shell
pipenv run generate_db -e=test
```

## Migrations

You can generate migrations using the following command
```shell
pipenv run alembic revision -m "{migration name here}" 
```

This will provide you with an templated migration file for you to add in your changes. This is done in the upgrade method
whilst removing is done in the downgrade method. For a tutorial on this head to [the alembic site](https://alembic.sqlalchemy.org/en/latest/tutorial.html)