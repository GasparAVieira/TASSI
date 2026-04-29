import uuid
from datetime import datetime

from sqlalchemy import DateTime, Float, ForeignKey, String, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class EpocSession(Base):
    __tablename__ = "epoc_sessions"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )

    participant_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    attention: Mapped[float | None] = mapped_column(
        Float,
        nullable=True,
    )

    engagement: Mapped[float | None] = mapped_column(
        Float,
        nullable=True,
    )

    excitement: Mapped[float | None] = mapped_column(
        Float,
        nullable=True,
    )

    interest: Mapped[float | None] = mapped_column(
        Float,
        nullable=True,
    )

    relaxation: Mapped[float | None] = mapped_column(
        Float,
        nullable=True,
    )

    stress: Mapped[float | None] = mapped_column(
        Float,
        nullable=True,
    )

    detected_command: Mapped[str | None] = mapped_column(
        String(50),
        nullable=True,
    )

    recorded_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        default=datetime.utcnow,
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )

    participant = relationship(
        "User",
        back_populates="epoc_sessions",
    )