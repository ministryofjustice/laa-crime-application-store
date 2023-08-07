from fastapi import FastAPI
from starlette.responses import RedirectResponse

from laa_crime_application_store_app.config.app_settings import get_app_settings
from laa_crime_application_store_app.routers import ping

app = FastAPI(
    title=get_app_settings().app_name,
    version="0.0.1",
    contact={
        "name": get_app_settings().contact_team,
        "email": get_app_settings().contact_email,
        "url": get_app_settings().app_repo,
    },
)

app.include_router(ping.router)


@app.get("/")
async def get_index():
    return RedirectResponse(url="/docs")
