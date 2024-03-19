FROM python:3.12-alpine3.18

WORKDIR /code

RUN apk --update-cache upgrade \
&& apk --no-cache add --upgrade gcc \
    musl-dev \
    libffi-dev \
    build-base \
    expat>2.6.0-r0

COPY ./Pipfile /code/Pipfile
COPY ./Pipfile.lock /code/Pipfile.lock
COPY ./laa_crime_application_store_app /code/laa_crime_application_store_app
COPY ./alembic.ini /code/alembic.ini
COPY ./alembic /code/alembic
COPY ./run.sh /code/run.sh
RUN chmod a+x /code/run.sh

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
ENTRYPOINT ["./run.sh"]
