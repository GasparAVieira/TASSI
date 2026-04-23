from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel

from app.core.enums import AccessibilityProfile, Direction


class NavigationRouteRequest(BaseModel):
    from_location_id: UUID
    to_location_id: UUID
    accessibility_profile: AccessibilityProfile | None = None


class NavigationStep(BaseModel):
    from_location_id: UUID
    to_location_id: UUID
    direction: Direction
    distance: Decimal
    bearing: Decimal | None = None
    instruction: str | None = None
    is_accessible: bool


class NavigationRouteResponse(BaseModel):
    profile_used: AccessibilityProfile
    total_cost: float
    total_distance: float
    steps: list[NavigationStep]
    location_sequence: list[UUID]