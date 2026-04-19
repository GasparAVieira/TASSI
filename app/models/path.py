import uuid

from sqlalchemy import Boolean, CheckConstraint, DateTime, Enum, ForeignKey, Numeric, UniqueConstraint, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class Path(Base):
    __tablename__ = "paths"

    __table_args__ = (
        CheckConstraint("from_location <> to_location", name="check_no_self_loop"),
        UniqueConstraint("from_location", "to_location", name="uq_paths_from_to"),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    from_location: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("locations.id"),
        nullable=False,
        index=True,
    )
    to_location: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("locations.id"),
        nullable=False,
        index=True,
    )
    distance: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    direction: Mapped[str] = mapped_column(
        Enum(
            "straight",
            "left",
            "right",
            "stairs_up",
            "stairs_down",
            "elevator_up",
            "elevator_down",
            "exit",
            name="path_direction",
        ),
        nullable=False,
    )
    is_accessible: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    created_at: Mapped[DateTime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    from_location_rel = relationship("Location", foreign_keys=[from_location])
    to_location_rel = relationship("Location", foreign_keys=[to_location])