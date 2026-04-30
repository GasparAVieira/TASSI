from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user_optional
from app.models.user import User
from app.schemas.navigation import NavigationRouteRequest, NavigationRouteResponse
from app.services.routing_service import calculate_route

from uuid import UUID
from app.models.path import Path
from app.models.location import Location

from app.core.enums import Language
from app.services.routing_service import select_instruction

from app.core.enums import AccessibilityProfile
from app.schemas.beacon_navigation_request import BeaconNavigationRequest

router = APIRouter(prefix="/api/v1/navigation", tags=["Navigation"])


@router.get("/route", response_model=NavigationRouteResponse)
def get_route(
    from_location_id: UUID,
    to_location_id: UUID,
    accessibility_profile: AccessibilityProfile  | None = None,
    db: Session = Depends(get_db),
    current_user: User | None = Depends(get_current_user_optional),
):
    try:
        return calculate_route(
            db=db,
            from_location_id=from_location_id,
            to_location_id=to_location_id,
            user=current_user,
            requested_profile=accessibility_profile,
        )
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc))
    
@router.get("/next/{current_location_id}")
def get_next_step(
    current_location_id: UUID,
    target_location_id: UUID,
    db: Session = Depends(get_db),
    current_user: User | None = Depends(get_current_user_optional),
):
    try:
        route = calculate_route(
            db=db,
            from_location_id=current_location_id,
            to_location_id=target_location_id,
            user=current_user,
        )
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc))

    if not route.steps:
        return {"message": "Already at destination"}

    return route.steps[0]

@router.post("/beacon-next")
def get_next_step_from_beacon(
    payload: BeaconNavigationRequest,
    db: Session = Depends(get_db),
    current_user: User | None = Depends(get_current_user_optional),
):
    location = (
        db.query(Location)
        .filter(Location.beacon_uuid == payload.beacon_uuid)
        .first()
    )

    if not location:
        raise HTTPException(
        status_code=404,
        detail="Beacon location not found",
    )

    try:
        route = calculate_route(
            db=db,
            from_location_id=location.id,
            to_location_id=payload.target_location_id,
            user=current_user,
        )
    except ValueError as exc:
        raise HTTPException(
            status_code=404,
            detail=str(exc),
        )

    if not route.steps:
        return {"message": "Already at destination"}

    return {
        "current_location_id": location.id,
        "current_location_name": location.name,
        "next_step": route.steps[0],
    }