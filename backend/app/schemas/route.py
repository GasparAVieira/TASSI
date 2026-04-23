from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict

from app.core.enums import Language


class RouteBase(BaseModel):
    owner_id: UUID | None = None
    name: str
    description: str | None = None
    is_public: bool = False
    language: Language = Language.pt


class RouteCreate(RouteBase):
    pass


class RouteUpdate(BaseModel):
    owner_id: UUID | None = None
    name: str | None = None
    description: str | None = None
    is_public: bool | None = None
    language: Language | None = None


class RouteResponse(RouteBase):
    id: UUID
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)