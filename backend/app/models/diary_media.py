import uuid

from sqlalchemy import DateTime, ForeignKey, Numeric, String, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func

from app.database import Base


class DiaryMedia(Base):
    __tablename__ = "diary_media"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    entry_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True),ForeignKey("diary_entries.id", ondelete="CASCADE"),nullable=False,)

    media_type: Mapped[str] = mapped_column(String(20), nullable=False)  # audio | image | video
    url: Mapped[str] = mapped_column(Text, nullable=False)
    duration_sec: Mapped[float | None] = mapped_column(Numeric(8, 2), nullable=True)
    transcription: Mapped[str | None] = mapped_column(Text, nullable=True)
    language: Mapped[str | None] = mapped_column(String(5), nullable=True)  # pt | en

    created_at: Mapped[DateTime] = mapped_column(DateTime(timezone=True),server_default=func.now(),nullable=False,)

    entry = relationship("DiaryEntry", back_populates="media_items")