import secure
from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint
from starlette.requests import Request
from starlette.responses import Response
from starlette.types import ASGIApp

SELF_REFERENCE = "'self'"

referrer = secure.ReferrerPolicy().no_referrer()
cache_control = secure.CacheControl().no_store()
x_frame_options = secure.XFrameOptions().sameorigin()
hsts = secure.StrictTransportSecurity().include_subdomains().preload().max_age(2592000)
csp = (
    secure.ContentSecurityPolicy()
    .default_src(SELF_REFERENCE)
    .base_uri(SELF_REFERENCE)
    .img_src(SELF_REFERENCE, "fastapi.tiangolo.com", "data:")
    .style_src(SELF_REFERENCE, "cdn.jsdelivr.net", "'unsafe-inline'")
    .script_src(SELF_REFERENCE, "cdn.jsdelivr.net", "'unsafe-inline'")
)

secure_headers = secure.Secure(
    referrer=referrer, cache=cache_control, xfo=x_frame_options, hsts=hsts, csp=csp
)


class SecureHeadersMiddleware(BaseHTTPMiddleware):
    def __init__(self, app: ASGIApp) -> None:
        super().__init__(app)

    async def dispatch(
        self, request: Request, call_next: RequestResponseEndpoint
    ) -> Response:
        response = await call_next(request)
        secure_headers.framework.fastapi(response)
        return response
