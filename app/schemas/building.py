from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class BuildingBase(BaseModel):
    name: str
    description: str | None = None


class BuildingCreate(BuildingBase):
    pass


class BuildingResponse(BuildingBase):
    id: UUID
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)