from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class PoiMediaBase(BaseModel):
    poi_id: UUID
    media_type: str
    file_url: str
    description: str | None = None


class PoiMediaCreate(PoiMediaBase):
    pass


class PoiMediaUpdate(BaseModel):
    poi_id: UUID | None = None
    media_type: str | None = None
    file_url: str | None = None
    description: str | None = None


class PoiMediaResponse(PoiMediaBase):
    id: UUID
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)