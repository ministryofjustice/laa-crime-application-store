import json
import logging.config
import os

import sentry_sdk
import structlog
from asgi_correlation_id import CorrelationIdMiddleware
from fastapi import FastAPI
from structlog.stdlib import LoggerFactory

from alembic.command import upgrade
from alembic.config import Config
from laa_crime_application_store_app.config import logging_config
from laa_crime_application_store_app.config.app_settings import get_app_settings
from laa_crime_application_store_app.middleware.secure_headers_middleware import (
    SecureHeadersMiddleware,
)
from laa_crime_application_store_app.routers import index, ping
from laa_crime_application_store_app.routers.v1 import application as v1_application


def send_event(event, hint):
    log_message = json.loads(event["logentry"]["message"])
    event["logentry"]["message"] = log_message["event"]
    event["logentry"]["params"] = log_message

    return event


structlog.configure(
    logger_factory=LoggerFactory(),
    processors=[
        structlog.stdlib.add_logger_name,
        structlog.stdlib.add_log_level,
        structlog.stdlib.PositionalArgumentsFormatter(),
        structlog.processors.TimeStamper(fmt="%Y-%m-%d %H:%M.%S"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
        structlog.processors.JSONRenderer(),
    ],
    wrapper_class=structlog.stdlib.BoundLogger,
    cache_logger_on_first_use=True,
)
logging.config.dictConfig(logging_config.config)

sentry_sdk.init(
    dsn=get_app_settings().sentry_dsn,
    release=get_app_settings().build_tag,
    sample_rate=1.0,
    traces_sample_rate=0.1,
    before_send=send_event,
)


app = FastAPI(
    title=get_app_settings().app_name,
    version="0.0.1",
    contact={
        "name": get_app_settings().contact_team,
        "email": get_app_settings().contact_email,
        "url": get_app_settings().app_repo,
    },
)

app.add_middleware(CorrelationIdMiddleware)
app.add_middleware(SecureHeadersMiddleware)

app.include_router(index.router)
app.include_router(ping.router)
app.include_router(v1_application.router, prefix="/v1")


@app.on_event("startup")
async def startup() -> None:
    alembic_cfg = Config(f"{os.getcwd()}/alembic.ini")
    upgrade(alembic_cfg, "head")
