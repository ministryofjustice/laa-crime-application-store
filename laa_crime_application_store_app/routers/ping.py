from fastapi import APIRouter, Depends

from laa_crime_application_store_app.config.app_settings import (
    AppSettings,
    get_app_settings,
)
from laa_crime_application_store_app.models.ping import Ping

router = APIRouter()


@router.get("/ping", response_model=Ping)
async def ping(settings: AppSettings = Depends(get_app_settings)):
    results = Ping(
        app_branch=settings.app_branch,
        build_date=settings.build_date,
        build_tag=settings.build_tag,
        commit_id=settings.commit_id,
    )

    return results
