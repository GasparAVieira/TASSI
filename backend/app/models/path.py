import uuid

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    DateTime,
    Enum,
    ForeignKey,
    Numeric,
    Text,
    UniqueConstraint,
    func,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.core.enums import Direction
from app.database import Base


class Path(Base):
    __tablename__ = "paths"

    __table_args__ = (
        UniqueConstraint("from_location", "to_location", name="uq_paths_from_to"),
        CheckConstraint("from_location <> to_location", name="ck_paths_no_self_loop"),
        CheckConstraint(
            "bearing IS NULL OR (bearing >= 0 AND bearing <= 360)",
            name="ck_paths_bearing_range",
        ),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )

    from_location: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("locations.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    to_location: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("locations.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    distance: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)

    weight_default: Mapped[float] = mapped_column(Numeric(10, 2), nullable=False)
    weight_wheelchair: Mapped[float | None] = mapped_column(Numeric(10, 2), nullable=True)
    weight_blind: Mapped[float | None] = mapped_column(Numeric(10, 2), nullable=True)

    direction: Mapped[Direction] = mapped_column(
        Enum(Direction, name="direction_enum"),
        nullable=False,
    )

    bearing: Mapped[float | None] = mapped_column(Numeric(5, 2), nullable=True)

    is_accessible: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        default=False,
    )

    instruction_pt: Mapped[str | None] = mapped_column(Text, nullable=True)
    instruction_en: Mapped[str | None] = mapped_column(Text, nullable=True)

    created_at: Mapped[DateTime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )