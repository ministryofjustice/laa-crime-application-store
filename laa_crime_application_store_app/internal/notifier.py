from typing import Optional

import httpx
import structlog

from laa_crime_application_store_app.schema.application_schema import Application

logger = structlog.get_logger(__name__)
http_client = httpx.AsyncClient(timeout=15.0)


class Notifier:
    async def notify(
        self,
        application: Application,
        scope: str = "nsm_caseworker",
        headers: Optional[dict[str, any]] = None,
    ):
        # TODO: add SNS implementation logic with swicth here
        return True
