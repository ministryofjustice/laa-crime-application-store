from uuid import UUID

import structlog
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from starlette.responses import Response

from laa_crime_application_store_app.data.database import get_db
from laa_crime_application_store_app.models.application import Application as App
from laa_crime_application_store_app.schema.application_schema import Application

router = APIRouter()
logger = structlog.getLogger(__name__)


@router.get("/application/{app_id}", response_model=App)
async def ping(app_id: UUID | None = None, db: Session = Depends(get_db)):
    logger.info("GETTING_APPLICATION", application_id=app_id)
    application = db.query(Application).filter(Application.id == app_id).first()
    if application is not None:
        logger.info("APPLICATION_FOUND", application_id=app_id)
        return App(**application.__dict__)

    logger.info("APPLICATION_NOT_FOUND", application_id=app_id)
    return Response(status_code=400)
