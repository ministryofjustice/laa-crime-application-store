import functools

import structlog

logger = structlog.get_logger(__name__)


def auth_logger(func):
    @functools.wraps(func)
    async def wrapper_auth_logger(*args, **kwargs):
        logger.info("SUCCESSFUL_AUTHENTICATION")
        return await func(*args, **kwargs)

    return wrapper_auth_logger
