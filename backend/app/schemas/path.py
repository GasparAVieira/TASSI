from datetime import datetime
from decimal import Decimal
from enum import Enum
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class PathDirection(str, Enum):
    straight = "straight"
    left = "left"
    right = "right"
    stairs_up = "stairs_up"
    stairs_down = "stairs_down"
    elevator_up = "elevator_up"
    elevator_down = "elevator_down"
    exit = "exit"


class PathBase(BaseModel):
    from_location: UUID
    to_location: UUID
    distance: Decimal
    direction: PathDirection
    is_accessible: bool = False


class PathCreate(PathBase):
    pass


class PathUpdate(BaseModel):
    from_location: UUID | None = None
    to_location: UUID | None = None
    distance: Decimal | None = None
    direction: PathDirection | None = None
    is_accessible: bool | None = None


class PathResponse(PathBase):
    id: UUID
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)