import uuid

from sqlalchemy import CheckConstraint, DateTime, ForeignKey, Integer, SmallInteger, Text, UniqueConstraint, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class Beacon(Base):
    __tablename__ = "beacons"

    __table_args__ = (
        UniqueConstraint("major", "minor", name="uq_beacons_major_minor"),
        CheckConstraint("major >= 0 AND major <= 65535", name="ck_beacons_major_range"),
        CheckConstraint("minor >= 0 AND minor <= 65535", name="ck_beacons_minor_range"),
        CheckConstraint(
            "battery_level IS NULL OR (battery_level >= 0 AND battery_level <= 100)",
            name="ck_beacons_battery_range",
        ),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )

    uuid: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        nullable=False,
        unique=True,
        index=True,
    )

    major: Mapped[int] = mapped_column(Integer, nullable=False)
    minor: Mapped[int] = mapped_column(Integer, nullable=False)

    name: Mapped[str | None] = mapped_column(Text, nullable=True)

    location_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("locations.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )

    battery_level: Mapped[int | None] = mapped_column(SmallInteger, nullable=True)
    last_seen: Mapped[DateTime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    created_at: Mapped[DateTime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )