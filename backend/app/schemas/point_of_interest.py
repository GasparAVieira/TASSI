from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class PointOfInterestBase(BaseModel):
    location_id: UUID
    name: str
    description: str | None = None
    category: str | None = None
    is_visible: bool = True


class PointOfInterestCreate(PointOfInterestBase):
    pass


class PointOfInterestUpdate(BaseModel):
    location_id: UUID | None = None
    name: str | None = None
    description: str | None = None
    category: str | None = None
    is_visible: bool | None = None


class PointOfInterestResponse(PointOfInterestBase):
    id: UUID
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)