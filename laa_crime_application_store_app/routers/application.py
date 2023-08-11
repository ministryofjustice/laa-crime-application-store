import uuid
from uuid import UUID

import structlog
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from starlette.responses import Response

from laa_crime_application_store_app.data.database import get_db
from laa_crime_application_store_app.models.application import Application as App
from laa_crime_application_store_app.models.laa_references.request.application_post_request import (
    ApplicationPostRequest,
)
from laa_crime_application_store_app.schema.application_schema import Application

router = APIRouter()
logger = structlog.getLogger(__name__)

responses = {
    201: {"description": "Application has been created"},
    202: {"description": "Request has been accepted"},
    # 400: {"description": "Validation has failed", "model": LaaReferencesErrorResponse},
    # 422: {
    #     "description": "Request cannot be processed",
    #     "model": LaaReferencesErrorResponse,
    # },
    424: {"description": "Error with Upstream service"},
}


@router.get("/application/{app_id}", response_model=App)
async def ping(app_id: UUID | None = None, db: Session = Depends(get_db)):
    logger.info("GETTING_APPLICATION", application_id=app_id)
    application = db.query(Application).filter(Application.id == app_id).first()
    if application is not None:
        logger.info("APPLICATION_FOUND", application_id=app_id)
        return App(**application.__dict__)

    logger.info("APPLICATION_NOT_FOUND", application_id=app_id)
    return Response(status_code=400)


@router.post("/application/", status_code=202, responses=responses)
async def post_application(
    request: ApplicationPostRequest, db: Session = Depends(get_db)
):
    logger.info("here")
    new_application = Application(
        id=uuid.uuid4(),
        claim_id=request.claim_id,
        version=1,
        json_schema_version=request.json_schema_version,
        application_state=request.application_state,
        application_risk=request.risk,
        application=request.application,
    )

    db.add(new_application)
    db.commit()
    return Response(status_code=201)
