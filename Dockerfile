FROM python:3.11-alpine3.15

WORKDIR /code

RUN apk --update-cache upgrade \
&& apk --no-cache add --upgrade gcc \
    musl-dev \
    build-base \
    expat

COPY ./Pipfile /code/Pipfile
COPY ./Pipfile.lock /code/Pipfile.lock
COPY ./laa_crime_application_store_app /code/laa_crime_application_store_app
COPY ./alembic.ini /code/alembic.ini
COPY ./alembic /code/alembic

RUN pip install --upgrade pip pipenv

RUN PIPENV_PIPFILE="/code/Pipfile" pipenv install --system --deploy

RUN addgroup -g 1001 -S appuser && adduser -u 1001 -S appuser -G appuser
RUN chown -R appuser:appuser /code
USER 1001

ARG COMMIT_ID
ENV COMMIT_ID ${COMMIT_ID}

ARG BUILD_DATE
ENV BUILD_DATE ${BUILD_DATE}

ARG BUILD_TAG
ENV BUILD_TAG ${BUILD_TAG}

ARG APP_BRANCH
ENV APP_BRANCH ${APP_BRANCH}

EXPOSE 8000
CMD ["uvicorn", "laa_crime_application_store_app.main:app", "--host", "0.0.0.0", "--port", "8000"]