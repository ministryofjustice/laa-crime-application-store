from sqlalchemy import Column, Integer, String
from sqlalchemy.dialects.postgresql import JSONB

from laa_crime_application_store_app.data.database import Base


class QueuedJob(Base):
    __tablename__ = "que_jobs"
    id = Column(Integer, nullable=False, primary_key=True)
    job_class = Column(String, nullable=False)
    args = Column(JSONB, nullable=False)
