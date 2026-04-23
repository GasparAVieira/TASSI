from datetime import datetime
from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel, ConfigDict

from app.core.enums import Direction


class PathBase(BaseModel):
    from_location: UUID
    to_location: UUID
    distance: Decimal
    weight_default: Decimal
    weight_wheelchair: Decimal | None = None
    weight_blind: Decimal | None = None
    direction: Direction
    bearing: Decimal | None = None
    is_bidirectional: bool = False
    is_accessible: bool = False
    instruction_pt: str | None = None
    instruction_en: str | None = None


class PathCreate(PathBase):
    pass


class PathUpdate(BaseModel):
    from_location: UUID | None = None
    to_location: UUID | None = None
    distance: Decimal | None = None
    weight_default: Decimal | None = None
    weight_wheelchair: Decimal | None = None
    weight_blind: Decimal | None = None
    direction: Direction | None = None
    bearing: Decimal | None = None
    is_bidirectional: bool | None = None
    is_accessible: bool | None = None
    instruction_pt: str | None = None
    instruction_en: str | None = None


class PathResponse(PathBase):
    id: UUID
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)