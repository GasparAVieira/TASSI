from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict
from typing_extensions import Literal


class DiaryMediaCreate(BaseModel):
    media_type: Literal["audio", "image", "video"]
    url: str
    duration_sec: Optional[float] = None
    transcription: Optional[str] = None
    language: Optional[Literal["pt", "en"]] = None


class DiaryMediaUpdate(BaseModel):
    url: Optional[str] = None
    duration_sec: Optional[float] = None
    transcription: Optional[str] = None
    language: Optional[Literal["pt", "en"]] = None


class DiaryMediaResponse(BaseModel):
    id: UUID
    media_type: str
    url: str
    duration_sec: Optional[float] = None
    transcription: Optional[str] = None
    language: Optional[str] = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)