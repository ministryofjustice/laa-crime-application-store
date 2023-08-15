from sqlalchemy import JSON, UUID, Column, Integer, Text

from laa_crime_application_store_app.data.database import Base


class Application(Base):
    __tablename__ = "application"

    id = Column(UUID, primary_key=True)
    claim_id = Column(UUID, nullable=False)
    version = Column(Integer, nullable=False)
    json_schema_version = Column(Integer, nullable=False)
    application_state = Column(Text, nullable=False)
    application_risk = Column(Text, nullable=False)
    application = Column(JSON, nullable=False)
