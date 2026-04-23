from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class BeaconBase(BaseModel):
    uuid: UUID
    major: int
    minor: int
    name: str | None = None
    location_id: UUID | None = None
    battery_level: int | None = None
    last_seen: datetime | None = None


class BeaconCreate(BeaconBase):
    pass


class BeaconUpdate(BaseModel):
    uuid: UUID | None = None
    major: int | None = None
    minor: int | None = None
    name: str | None = None
    location_id: UUID | None = None
    battery_level: int | None = None
    last_seen: datetime | None = None


class BeaconResponse(BeaconBase):
    id: UUID
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)