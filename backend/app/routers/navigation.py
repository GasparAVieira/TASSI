from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user_optional
from app.models.user import User
from app.schemas.navigation import NavigationRouteRequest, NavigationRouteResponse
from app.services.routing_service import calculate_route

router = APIRouter(prefix="/api/v1/navigation", tags=["Navigation"])


@router.post("/route", response_model=NavigationRouteResponse)
def get_route(
    payload: NavigationRouteRequest,
    db: Session = Depends(get_db),
    current_user: User | None = Depends(get_current_user_optional),
):
    try:
        return calculate_route(
            db=db,
            from_location_id=payload.from_location_id,
            to_location_id=payload.to_location_id,
            user=current_user,
            requested_profile=payload.accessibility_profile,
        )
    except ValueError as exc:
        raise HTTPException(status_code=404, detail=str(exc))