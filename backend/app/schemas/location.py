from datetime import datetime
from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel, ConfigDict

from app.core.enums import LocationType, ModelType


class LocationBase(BaseModel):
    building_id: UUID | None = None
    type: LocationType
    name: str
    floor: int | None = None
    geom_wkt: str
    local_x: Decimal | None = None
    local_y: Decimal | None = None
    description: str | None = None
    is_accessible: bool = False
    model_url: str | None = None
    model_type: ModelType | None = None


class LocationCreate(LocationBase):
    pass


class LocationUpdate(BaseModel):
    building_id: UUID | None = None
    type: LocationType | None = None
    name: str | None = None
    floor: int | None = None
    geom_wkt: str | None = None
    local_x: Decimal | None = None
    local_y: Decimal | None = None
    description: str | None = None
    is_accessible: bool | None = None
    model_url: str | None = None
    model_type: ModelType | None = None


class LocationResponse(BaseModel):
    id: UUID
    building_id: UUID | None = None
    type: LocationType
    name: str
    floor: int | None = None
    geom_wkt: str | None = None
    local_x: Decimal | None = None
    local_y: Decimal | None = None
    description: str | None = None
    is_accessible: bool
    model_url: str | None = None
    model_type: ModelType | None = None
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)