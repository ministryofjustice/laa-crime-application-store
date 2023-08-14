from sqlalchemy import UUID, Column, Integer, Text

from laa_crime_application_store_app.data.database import Base


class Application(Base):
    __tablename__ = "application"

    id = Column(UUID, primary_key=True)
    current_version = Column(Integer, nullable=False)
    application_state = Column(Text, nullable=False)
    application_risk = Column(Text, nullable=False)
