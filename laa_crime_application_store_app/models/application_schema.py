from sqlalchemy import UUID, Column, DateTime, Integer, Text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import relationship

from laa_crime_application_store_app.data.database import Base


class Application(Base):
    __tablename__ = "application"

    id = Column(UUID, primary_key=True)
    current_version = Column(Integer, nullable=False)
    application_state = Column(Text, nullable=False)
    application_risk = Column(Text, nullable=False)
    application_type = Column(Text, nullable=False)
    versions = relationship("ApplicationVersion", back_populates="application_record")
    events = Column(JSONB)
    updated_at = Column(DateTime, nullable=False)
