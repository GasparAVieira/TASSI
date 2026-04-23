from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class RouteStepBase(BaseModel):
    route_id: UUID
    location_id: UUID
    step_order: int
    note: str | None = None


class RouteStepCreate(RouteStepBase):
    pass


class RouteStepUpdate(BaseModel):
    route_id: UUID | None = None
    location_id: UUID | None = None
    step_order: int | None = None
    note: str | None = None


class RouteStepResponse(RouteStepBase):
    id: UUID
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)