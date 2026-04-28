import uuid

from sqlalchemy import Boolean, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import mapped_column, Mapped

from app.database import Base

class NotificationTemplate(Base):
    __tablename__ = "notification_templates"

    id = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    type = mapped_column(String(50), nullable=False, unique=True)

    title_pt = mapped_column(String(120), nullable=False)
    message_pt = mapped_column(Text, nullable=False)

    title_en = mapped_column(String(120), nullable=True)
    message_en = mapped_column(Text, nullable=True)

    priority = mapped_column(String(20), default="normal", nullable=False)
    action = mapped_column(String(50), nullable=True)

    is_active = mapped_column(Boolean, default=True, nullable=False)