from datetime import datetime
from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel, ConfigDict

from app.core.enums import LocationType, ModelType


class LocationBase(BaseModel):
    type: LocationType
    name: str

    floor: int | None = None
    local_x: Decimal
    local_y: Decimal

    description: str | None = None

    beacon_uuid: UUID | None = None
    beacon_major: int | None = None
    beacon_minor: int | None = None
    beacon_battery_level: int | None = None

    model_url: str | None = None
    model_type: ModelType | None = None


class LocationCreate(LocationBase):
    pass


class LocationUpdate(BaseModel):
    type: LocationType | None = None
    name: str | None = None

    floor: int | None = None
    local_x: Decimal | None = None
    local_y: Decimal | None = None

    description: str | None = None

    beacon_uuid: UUID | None = None
    beacon_major: int | None = None
    beacon_minor: int | None = None
    beacon_battery_level: int | None = None

    model_url: str | None = None
    model_type: ModelType | None = None


class LocationResponse(BaseModel):
    id: UUID

    type: LocationType
    name: str

    floor: int | None = None
    local_x: Decimal
    local_y: Decimal

    description: str | None = None

    beacon_uuid: UUID | None = None
    beacon_major: int | None = None
    beacon_minor: int | None = None
    beacon_battery_level: int | None = None

    model_url: str | None = None
    model_type: ModelType | None = None

    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)