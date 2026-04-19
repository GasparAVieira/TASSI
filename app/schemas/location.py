from datetime import datetime
from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class LocationBase(BaseModel):
    name: str
    floor: int
    x: Decimal
    y: Decimal
    description: str | None = None
    model_url: str | None = None
    model_type: str | None = None


class LocationCreate(LocationBase):
    pass


class LocationUpdate(BaseModel):
    name: str | None = None
    floor: int | None = None
    x: Decimal | None = None
    y: Decimal | None = None
    description: str | None = None
    model_url: str | None = None
    model_type: str | None = None


class LocationResponse(LocationBase):
    id: UUID
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)