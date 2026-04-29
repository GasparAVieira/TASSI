from datetime import datetime
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class EpocSessionCreate(BaseModel):
    attention: Optional[float] = None
    engagement: Optional[float] = None
    excitement: Optional[float] = None
    interest: Optional[float] = None
    relaxation: Optional[float] = None
    stress: Optional[float] = None
    detected_command: Optional[str] = None
    recorded_at: Optional[datetime] = None


class EpocSessionUpdate(BaseModel):
    attention: Optional[float] = None
    engagement: Optional[float] = None
    excitement: Optional[float] = None
    interest: Optional[float] = None
    relaxation: Optional[float] = None
    stress: Optional[float] = None
    detected_command: Optional[str] = None
    recorded_at: Optional[datetime] = None


class EpocSessionResponse(BaseModel):
    id: UUID
    participant_id: UUID

    attention: Optional[float] = None
    engagement: Optional[float] = None
    excitement: Optional[float] = None
    interest: Optional[float] = None
    relaxation: Optional[float] = None
    stress: Optional[float] = None

    detected_command: Optional[str] = None

    recorded_at: datetime
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)