from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class BeaconBase(BaseModel):
    uuid: str
    major: int
    minor: int
    name: str | None = None
    location_id: UUID
    battery_level: int | None = None
    last_seen: datetime | None = None


class BeaconCreate(BeaconBase):
    pass


class BeaconResponse(BeaconBase):
    id: UUID
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)