import typing

from starlette.responses import Response


class SecureJsonResponse(Response):
    media_type = "application/json; charset=utf-8"

    def render(self, content: typing.Any) -> bytes:
        return content.model_dump_json()
