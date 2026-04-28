from datetime import datetime
from uuid import UUID

from pydantic import BaseModel


class NotificationResponse(BaseModel):
    id: UUID
    type: str
    title: str
    message: str
    priority: str
    action: str | None = None
    shown_at: datetime | None = None
    read_at: datetime | None = None
    dismissed_at: datetime | None = None
    expires_at: datetime | None = None

    model_config = {
        "from_attributes": True
    }


class NotificationTemplateCreate(BaseModel):
    type: str
    title_pt: str
    message_pt: str
    title_en: str | None = None
    message_en: str | None = None
    priority: str = "normal"
    action: str | None = None
    is_active: bool = True


class NotificationTemplateUpdate(BaseModel):
    title_pt: str | None = None
    message_pt: str | None = None
    title_en: str | None = None
    message_en: str | None = None
    priority: str | None = None
    action: str | None = None
    is_active: bool | None = None


class NotificationTemplateResponse(BaseModel):
    id: UUID
    type: str
    title_pt: str
    message_pt: str
    title_en: str | None = None
    message_en: str | None = None
    priority: str
    action: str | None = None
    is_active: bool

    model_config = {
        "from_attributes": True
    }