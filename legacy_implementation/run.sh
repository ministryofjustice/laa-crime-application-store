#!/bin/sh
cd /code

alembic upgrade head && uvicorn laa_crime_application_store_app.main:app --host 0.0.0.0 --port 8000
