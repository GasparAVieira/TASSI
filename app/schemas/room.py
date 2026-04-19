from datetime import datetime
from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class RoomBase(BaseModel):
    building_id: UUID
    location_id: UUID | None = None
    name: str
    floor: int
    is_accessible: bool = False
    x: Decimal | None = None
    y: Decimal | None = None


class RoomCreate(RoomBase):
    pass


class RoomResponse(RoomBase):
    id: UUID
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)