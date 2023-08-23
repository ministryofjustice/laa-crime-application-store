from typing import Optional

import httpx
import structlog
from circuitbreaker import circuit

from laa_crime_application_store_app.schema.application_schema import Application

logger = structlog.get_logger(__name__)
http_client = httpx.AsyncClient(timeout=15.0)


class Notifier:
    async def notify_via_http(
        self, application: Application, headers: Optional[dict[str, any]] = None
    ):
        headers = self.__setup_default_headers(
            headers, {"Content-Type": "application/json"}
        )
        message = self.__extra_metadata(application)
        body = message.json()

        response = await self.__call_endpoint(
            method="POST", endpoint="/application_versions", body=body, headers=headers
        )
        return response

    @circuit()
    async def __call_endpoint(
        self,
        method: str,
        endpoint: str,
        params: Optional[dict[str, str]] = None,
        headers: Optional[dict[str, any]] = None,
        body: Optional[any] = None,
    ):
        # TODO: don;t hardcode this
        http_client.base_url = "http://localhost:3002"
        # TODO: some sort of auth header - done here to allow shorter timeouts
        try:
            request = http_client.build_request(
                method=method,
                url=endpoint,
                params=params,
                headers=headers,
                content=body,
            )
            logger.info("NSM_CW_Request_Made", endpoint=request.url)
            response = await http_client.send(request)
            logger.info(
                "NSM_CW_Response_Returned",
                endpoint=request.url,
                status_code=response.status_code,
            )
            return response
        except Exception as e:
            logger.error("NSM_CW_Endpoint_Error", endpoint=request.url, exception=e)
            return None

    @staticmethod
    def __extra_metadata(application: Application):
        metadata = {
            "id": application.id,
            "state": application.application_state,
            "risk": application.application_risk,
            "current_version": application.current_version,
        }
        return metadata

    @staticmethod
    def __setup_default_headers(headers: dict, default_headers: dict):
        if headers is None:
            headers = {}

        headers.update(default_headers)

        return headers
