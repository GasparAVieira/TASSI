from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class FaqBase(BaseModel):
    question: str
    answer: str
    category: str | None = None
    display_order: int = 0
    is_visible: bool = True


class FaqCreate(FaqBase):
    pass


class FaqUpdate(BaseModel):
    question: str | None = None
    answer: str | None = None
    category: str | None = None
    display_order: int | None = None
    is_visible: bool | None = None


class FaqResponse(FaqBase):
    id: UUID
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)