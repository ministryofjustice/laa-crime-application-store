# laa-crime-application-store

LAA Crime Application Store is a service to provide the ability to store and version crime applications from CRM forms. 

## Setting up the service

This application is currently set to use python 3.11

### Installing pipenv

This application uses pipenv for its virtual environment. To get started run the following commands
```shell
$ pip3 install pipenv
$ pipenv shell
$ pipenv install --dev
```

### Setting up pre-commit

To ensure the code standards of our service, we are using a series of linters to help us adhere to PEP8 and general coding guidlines.
Before working on the codebase run the following command
```shell
pipenv run pre-commit install
```
This will add a git hook into your repo that will run the commands from [the pre-commit config](.pre-commit-config.yaml)
This current performs the following functions:
- isort - orders the imports
- black - formats the code to python standards
- flake8 - ensures the code is PEP8 standards
- pytest - runs tests with coverage (100% line currently)

On the rare occasion you may need to bypass this, you can do so with `git commit --no-verify`

### Setting up the database

We are currently using [Alembic](https://alembic.sqlalchemy.org/en/latest/index.html) for our database migrations.
Information on our usage can be found [here](alembic/README.md)

### Running the application

Running the application can be done by using the following command from the root of the project
```shell
pipenv run uvicorn laa_crime_application_store_app.main:app --reload
```
The application will reload on code changes to save on rebuild times

### Running locally with Docker

To run via a docker container:
1. Perform the docker build with: 

`docker-compose build app`
2. You can optionally set build arguments by adding:

`--build-arg arg_name='arg_value'`
3. Run the container with:

`docker-compose up app`

### Running tests

Unit tests
Run units tests with the following command from the root of the project
```shell
pipenv run pytest --cov-report term --cov=laa_crime_application_store_app tests/
```

### Running linters

Running linters can be done using the following command from the root of the project
```shell
pipenv run black .
pipenv run isort .
pipenv run flake8
```