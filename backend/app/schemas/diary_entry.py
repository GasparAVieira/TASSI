from datetime import datetime
from typing import Any, Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field
from typing_extensions import Literal

from app.schemas.diary_media import DiaryMediaCreate, DiaryMediaResponse


class DiaryEntryCreate(BaseModel):
    entry_type: Literal["text", "audio", "image", "video"]
    body: Optional[str] = None
    duration_sec: Optional[float] = None
    recorded_at: datetime

    location_id: Optional[UUID] = None
    building_id: Optional[UUID] = None

    context_notes: Optional[dict[str, Any]] = None
    is_synced: bool = True

    media_items: list[DiaryMediaCreate] = Field(default_factory=list)


class DiaryEntryUpdate(BaseModel):
    body: Optional[str] = None
    duration_sec: Optional[float] = None
    recorded_at: Optional[datetime] = None

    location_id: Optional[UUID] = None
    building_id: Optional[UUID] = None

    context_notes: Optional[dict[str, Any]] = None
    is_synced: Optional[bool] = None
    media_items: Optional[list[DiaryMediaCreate]] = None


class DiaryEntryResponse(BaseModel):
    id: UUID
    participant_id: UUID
    entry_type: Literal["text", "audio", "image", "video"]
    body: Optional[str] = None
    duration_sec: Optional[float] = None
    recorded_at: datetime

    location_id: Optional[UUID] = None
    building_id: Optional[UUID] = None

    context_notes: Optional[dict[str, Any]] = None
    is_synced: bool
    created_at: datetime
    updated_at: datetime

    media_items: list[DiaryMediaResponse] = Field(default_factory=list)

    model_config = ConfigDict(from_attributes=True)


class DiaryEntryListResponse(BaseModel):
    items: list[DiaryEntryResponse]
    total: int
    limit: int
    offset: int