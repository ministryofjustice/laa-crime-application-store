import uuid

from sqlalchemy import UUID, Column, String

from laa_crime_application_store_app.data.database import Base


class Subscriber(Base):
    __tablename__ = "subscriber"

    id = Column(UUID, primary_key=True, default=uuid.uuid4)
    subscriber_type = Column(String, nullable=False)
    webhook_url = Column(String, nullable=False)
