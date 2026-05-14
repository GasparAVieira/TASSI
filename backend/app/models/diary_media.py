import uuid

from sqlalchemy import DateTime, Enum, ForeignKey, Numeric, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func

from app.core.enums import Language, MediaType
from app.database import Base


class DiaryMedia(Base):
    __tablename__ = "diary_media"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    entry_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True),ForeignKey("diary_entries.id", ondelete="CASCADE"),nullable=False,)

    # Bound to PG enum types — see comment on DiaryEntry.entry_type for why.
    media_type: Mapped[MediaType] = mapped_column(
        Enum(MediaType, name="media_type_enum"),
        nullable=False,
    )
    url: Mapped[str] = mapped_column(Text, nullable=False)
    duration_sec: Mapped[float | None] = mapped_column(Numeric(8, 2), nullable=True)
    transcription: Mapped[str | None] = mapped_column(Text, nullable=True)
    language: Mapped[Language | None] = mapped_column(
        Enum(Language, name="language_enum"),
        nullable=True,
    )

    created_at: Mapped[DateTime] = mapped_column(DateTime(timezone=True),server_default=func.now(),nullable=False,)

    entry = relationship("DiaryEntry", back_populates="media_items")