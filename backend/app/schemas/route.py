from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class RouteBase(BaseModel):
    name: str
    description: str | None = None


class RouteCreate(RouteBase):
    pass


class RouteUpdate(BaseModel):
    name: str | None = None
    description: str | None = None


class RouteResponse(RouteBase):
    id: UUID
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)