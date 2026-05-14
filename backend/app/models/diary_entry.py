import uuid

from sqlalchemy import Boolean, DateTime, Enum, ForeignKey, Index, Numeric, Text
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy.sql import func

from app.core.enums import DiaryEntryType
from app.database import Base


class DiaryEntry(Base):
    __tablename__ = "diary_entries"
    __table_args__ = (
        Index("ix_diary_entries_participant_recorded", "participant_id", "recorded_at"),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    participant_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True),ForeignKey("users.id", ondelete="CASCADE"),nullable=False,)

    # Bound to the PG `diary_entry_type_enum` type so SQLAlchemy emits
    # the right cast on INSERT. Plain String(20) is rejected by Postgres
    # because the column is a custom enum, not VARCHAR.
    entry_type: Mapped[DiaryEntryType] = mapped_column(
        Enum(DiaryEntryType, name="diary_entry_type_enum"),
        nullable=False,
    )
    body: Mapped[str | None] = mapped_column(Text, nullable=True)
    duration_sec: Mapped[float | None] = mapped_column(Numeric(8, 2), nullable=True)

    recorded_at: Mapped[DateTime] = mapped_column(DateTime(timezone=True), nullable=False)

    location_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True),ForeignKey("locations.id"),nullable=True,)

    building_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True),ForeignKey("buildings.id"),nullable=True,)

    context_notes: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    is_synced: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)

    created_at: Mapped[DateTime] = mapped_column(DateTime(timezone=True),server_default=func.now(),nullable=False,)

    updated_at: Mapped[DateTime] = mapped_column(DateTime(timezone=True),server_default=func.now(),onupdate=func.now(),nullable=False,)

    participant = relationship("User", back_populates="diary_entries")
    media_items = relationship("DiaryMedia",back_populates="entry",cascade="all, delete-orphan",)
    comments = relationship("DiaryEntryComment",back_populates="entry",cascade="all, delete-orphan",order_by="DiaryEntryComment.created_at",)

    location = relationship("Location",foreign_keys=[location_id],)
    building = relationship("Building",foreign_keys=[building_id],)