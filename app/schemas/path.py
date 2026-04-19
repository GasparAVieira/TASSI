from datetime import datetime
from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class PathBase(BaseModel):
    from_location: UUID
    to_location: UUID
    distance: Decimal
    direction: str
    is_accessible: bool = False


class PathCreate(PathBase):
    pass


class PathUpdate(BaseModel):
    from_location: UUID | None = None
    to_location: UUID | None = None
    distance: Decimal | None = None
    direction: str | None = None
    is_accessible: bool | None = None


class PathResponse(PathBase):
    id: UUID
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)