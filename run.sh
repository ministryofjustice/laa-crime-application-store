#!/bin/sh
cd /usr/src/app

python ./alembic/generate_db.py && uvicorn laa_crime_application_store_app.main:app --host 0.0.0.0 --port 8000

