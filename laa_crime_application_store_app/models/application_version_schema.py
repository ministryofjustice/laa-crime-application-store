import uuid

from sqlalchemy import JSON, UUID, Column, ForeignKey, Integer
from sqlalchemy.orm import relationship

from laa_crime_application_store_app.data.database import Base


class ApplicationVersion(Base):
    __tablename__ = "application_version"

    id = Column(UUID, primary_key=True, default=uuid.uuid4)
    application_id = Column(UUID, ForeignKey("application.id"), nullable=False)
    version = Column(Integer, nullable=False)
    json_schema_version = Column(Integer, nullable=False)
    application = Column(JSON, nullable=False)
    application_record = relationship("Application", back_populates="versions")
