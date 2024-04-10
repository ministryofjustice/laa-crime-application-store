from pydantic import BaseModel


class Subscriber(BaseModel):
    subscriber_type: str
    webhook_url: str
