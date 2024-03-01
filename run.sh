#!/bin/sh
cd /usr/src/app

echo 'Username'
echo $POSTGRES_USERNAME
echo 'pass'
echo $POSTGRES_PASSWORD
echo 'host'
echo $POSTGRES_HOSTNAME
echo 'name'
echo $POSTGRES_NAME

python ./alembic/generate_db.py && uvicorn laa_crime_application_store_app.main:app --host 0.0.0.0 --port 8000echo 'Username'
