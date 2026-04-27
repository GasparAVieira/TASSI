from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class BuildingBase(BaseModel):
    code: str
    name: str
    description: str | None = None


class BuildingCreate(BuildingBase):
    pass


class BuildingUpdate(BaseModel):
    code: str | None = None
    name: str | None = None
    description: str | None = None


class BuildingResponse(BuildingBase):
    id: UUID
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)