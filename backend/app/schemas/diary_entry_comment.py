from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class AuthorSummary(BaseModel):
    id: UUID
    full_name: str
    role: str

    model_config = ConfigDict(from_attributes=True)


class DiaryEntryCommentCreate(BaseModel):
    body: str = Field(min_length=1)


class DiaryEntryCommentUpdate(BaseModel):
    body: Optional[str] = None


class DiaryEntryCommentResponse(BaseModel):
    id: UUID
    entry_id: UUID
    author_id: Optional[UUID] = None
    body: str
    created_at: datetime
    updated_at: datetime
    author: Optional[AuthorSummary] = None

    model_config = ConfigDict(from_attributes=True)
