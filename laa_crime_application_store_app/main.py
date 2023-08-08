import logging.config

import structlog
from asgi_correlation_id import CorrelationIdMiddleware
from fastapi import FastAPI
from starlette.responses import RedirectResponse
from structlog.stdlib import LoggerFactory

from laa_crime_application_store_app.config import logging_config
from laa_crime_application_store_app.config.app_settings import get_app_settings
from laa_crime_application_store_app.routers import ping

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

app.include_router(ping.router)


@app.get("/")
async def get_index():
    return RedirectResponse(url="/docs")
