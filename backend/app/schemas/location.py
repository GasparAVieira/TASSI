from datetime import datetime
from decimal import Decimal
from enum import Enum
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class LocationModelType(str, Enum):
    gltf = "gltf"
    glb = "glb"
    obj = "obj"
    fbx = "fbx"
    usdz = "usdz"


class LocationBase(BaseModel):
    name: str
    floor: int
    x: Decimal
    y: Decimal
    description: str | None = None
    model_url: str | None = None
    model_type: LocationModelType | None = None


class LocationCreate(LocationBase):
    pass


class LocationUpdate(BaseModel):
    name: str | None = None
    floor: int | None = None
    x: Decimal | None = None
    y: Decimal | None = None
    description: str | None = None
    model_url: str | None = None
    model_type: LocationModelType | None = None


class LocationResponse(LocationBase):
    id: UUID
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)