import functools

import structlog
from fastapi import HTTPException

from laa_crime_application_store_app.config.auth_settings import get_auth_settings

logger = structlog.get_logger(__name__)


def auth_logger(func):
    @functools.wraps(func)
    async def wrapper_auth_logger(*args, **kwargs):
        request = kwargs.get("request", None)
        if request.client is None:
            # this is when testing
            # not happy with this as a check
            return await func(*args, **kwargs)
        allowed_host = request.client.host in get_auth_settings().safe_clients
        if get_auth_settings().azure_authentication:
            logger.info("SUCCESSFUL_AUTHENTICATION")
        else:
            if not allowed_host:
                logger.info("AZURE AUTHENTICATION CANNOT BE SWITCHED OFF")
                raise HTTPException(status_code=401, detail="Authentication Error")
            else:
                logger.info("AZURE_AUTHENTICATION SAFELY SWITCHED OFF")
        return await func(*args, **kwargs)

    return wrapper_auth_logger
