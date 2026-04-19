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


class PathResponse(PathBase):
    id: UUID
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)