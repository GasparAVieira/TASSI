from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class RoomBase(BaseModel):
    building_id: UUID
    location_id: UUID
    code: str
    name: str
    floor: int


class RoomCreate(RoomBase):
    pass


class RoomUpdate(BaseModel):
    building_id: UUID | None = None
    location_id: UUID | None = None
    code: str | None = None
    name: str | None = None
    floor: int | None = None


class RoomResponse(RoomBase):
    id: UUID
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)