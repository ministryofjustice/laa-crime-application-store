from sqlalchemy import UUID, Column, Integer, Text
from sqlalchemy.orm import relationship

from laa_crime_application_store_app.data.database import Base
from laa_crime_application_store_app.schema.application_version_schema import (
    ApplicationVersion,
)


class Application(Base):
    __tablename__ = "application"

    id = Column(UUID, primary_key=True)
    current_version = Column(Integer, nullable=False)
    application_state = Column(Text, nullable=False)
    application_risk = Column(Text, nullable=False)
    versions = relationship("ApplicationVersion", back_populates="application_record")
