from typing import Optional

import httpx
import structlog
from circuitbreaker import circuit

from laa_crime_application_store_app.config.external_server_settings import (
    ExternalServerSettings,
    get_external_server_settings,
)
from laa_crime_application_store_app.models.application_metadata import (
    ApplicationMetadata,
)
from laa_crime_application_store_app.models.application_post_request import (
    ApplicationPostRequest,
)
from laa_crime_application_store_app.schema.application_schema import Application

logger = structlog.get_logger(__name__)
http_client = httpx.AsyncClient(timeout=15.0)


class Notifier:
    @property
    def settings(self) -> ExternalServerSettings:
        return get_external_server_settings()

    async def notify(
        self,
        application: Application,
        scope: str = "nsm_caseworker",
        headers: Optional[dict[str, any]] = None,
    ):
        # TODO: add SNS implementation logic with swicth here
        response = await self.notify_via_http(
            application=application, scope=scope, headers=headers
        )
        return response

    async def notify_via_http(
        self,
        application: Application,
        scope: str = "nsm_caseworker",
        headers: Optional[dict[str, any]] = None,
    ):
        # TODO: some sort of auth header - done here as not timeout on header
        # headers = self.__setup_default_headers(headers, {})
        headers = self.__setup_default_headers(
            headers, {"Content-Type": "application/json"}
        )
        message = self.__extra_metadata(application)
        body = message.model_dump_json()

        response = await self.__call_endpoint(
            method="PUT",
            endpoint=f"/application_versions/{application.id}",
            body=body,
            headers=headers,
            scope=scope,
        )
        return response

    @circuit()
    async def __call_endpoint(
        self,
        method: str,
        endpoint: str,
        scope: str,
        params: Optional[dict[str, str]] = None,
        headers: Optional[dict[str, any]] = None,
        body: Optional[any] = None,
    ):
        http_client.base_url = self.settings.url(scope=scope)
        try:
            request = http_client.build_request(
                method=method,
                url=endpoint,
                params=params,
                headers=headers,
                content=body,
            )
            logger.info(f"{scope}_Request_Made", endpoint=request.url)
            response = await http_client.send(request)
            logger.info(
                f"{scope}_Response_Returned",
                endpoint=request.url,
                status_code=response.status_code,
            )
            return response
        except Exception as e:
            logger.error(f"{scope}_Endpoint_Error", endpoint=request.url, exception=e)
            return None

    @staticmethod
    def __extra_metadata(application: Application):
        metadata = ApplicationMetadata(
            id=application.id,
            state=application.application_state,
            risk=application.application_risk,
            current_version=application.current_version,
        )
        request_body = ApplicationPostRequest(application=metadata)
        return request_body

    @staticmethod
    def __setup_default_headers(headers: dict, default_headers: dict):
        if headers is None:
            headers = {}

        headers.update(default_headers)

        return headers
