from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict


class DiaryEntryBase(BaseModel):
    title: str
    text_content: Optional[str] = None
    transcription: Optional[str] = None
    is_public: bool = False
    location_label: Optional[str] = None
    user_id: str


class DiaryEntryCreate(DiaryEntryBase):
    pass


class DiaryEntryUpdate(BaseModel):
    title: Optional[str] = None
    text_content: Optional[str] = None
    transcription: Optional[str] = None
    is_public: Optional[bool] = None
    location_label: Optional[str] = None


class DiaryEntryResponse(DiaryEntryBase):
    id: int
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)