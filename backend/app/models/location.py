import uuid

from geoalchemy2 import Geometry
from sqlalchemy import Boolean, DateTime, Enum, ForeignKey, Numeric, SmallInteger, Text, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.core.enums import LocationType, ModelType
from app.database import Base


class Location(Base):
    __tablename__ = "locations"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )

    building_id: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("buildings.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )

    type: Mapped[LocationType] = mapped_column(
        Enum(LocationType, name="location_type_enum"),
        nullable=False,
        index=True,
    )

    name: Mapped[str] = mapped_column(Text, nullable=False)

    floor: Mapped[int | None] = mapped_column(
        SmallInteger,
        nullable=True,
        index=True,
    )

    geom: Mapped[object] = mapped_column(
        Geometry(geometry_type="POINT", srid=4326),
        nullable=False,
    )

    local_x: Mapped[float | None] = mapped_column(
        Numeric(10, 4),
        nullable=True,
    )
    local_y: Mapped[float | None] = mapped_column(
        Numeric(10, 4),
        nullable=True,
    )

    description: Mapped[str | None] = mapped_column(Text, nullable=True)

    is_accessible: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        default=False,
    )

    model_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    model_type: Mapped[ModelType | None] = mapped_column(
        Enum(ModelType, name="model_type_enum"),
        nullable=True,
    )

    created_at: Mapped[DateTime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )
    updated_at: Mapped[DateTime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
        onupdate=func.now(),
    )