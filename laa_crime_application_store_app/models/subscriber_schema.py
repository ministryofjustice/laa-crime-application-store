from sqlalchemy import Column, String

from laa_crime_application_store_app.data.database import Base


class Subscriber(Base):
    __tablename__ = "subscriber"

    subscriber_type = Column(String, nullable=False, primary_key=True)
    webhook_url = Column(
        String,
        nullable=False,
        primary_key=True,
    )
