import uuid
from datetime import datetime

from sqlalchemy import (Boolean,DateTime,Enum,ForeignKey,Integer,Numeric,SmallInteger,Text,func,)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.enums import LocationType, ModelType
from app.database import Base

class Location(Base):
    __tablename__ = "locations"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )

    type: Mapped[LocationType] = mapped_column(
        Enum(LocationType, name="location_type_enum"),
        nullable=False,
        index=True,
    )

    name: Mapped[str] = mapped_column(
        Text,
        nullable=False,
    )

    floor: Mapped[int | None] = mapped_column(
        SmallInteger,
        nullable=True,
        index=True,
    )

    local_x: Mapped[float] = mapped_column(
        Numeric(10, 4),
        nullable=False,
    )

    local_y: Mapped[float] = mapped_column(
        Numeric(10, 4),
        nullable=False,
    )

    description: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )

    beacon_uuid: Mapped[uuid.UUID | None] = mapped_column(
        UUID(as_uuid=True),
        nullable=True,
    )

    beacon_major: Mapped[int | None] = mapped_column(
        Integer,
        nullable=True,
    )

    beacon_minor: Mapped[int | None] = mapped_column(
        Integer,
        nullable=True,
    )

    model_url: Mapped[str | None] = mapped_column(
        Text,
        nullable=True,
    )

    model_type: Mapped[ModelType | None] = mapped_column(
        Enum(ModelType, name="model_type_enum"),
        nullable=True,
    )

    beacon_battery_level: Mapped[int | None] = mapped_column(
        Integer,
        nullable=True,
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )

    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
        onupdate=func.now(),
    )