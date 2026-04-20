from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import require_admin
from app.models.location import Location
from app.models.route import Route
from app.models.route_step import RouteStep
from app.models.user import User
from app.schemas.route_step import RouteStepCreate, RouteStepResponse, RouteStepUpdate

router = APIRouter(prefix="/api/v1/route-steps", tags=["Route Steps"])


@router.post("/", response_model=RouteStepResponse, status_code=status.HTTP_201_CREATED)
def create_route_step(
    payload: RouteStepCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    route = db.query(Route).filter(Route.id == payload.route_id).first()
    if not route:
        raise HTTPException(status_code=404, detail="Route not found")

    location = db.query(Location).filter(Location.id == payload.location_id).first()
    if not location:
        raise HTTPException(status_code=404, detail="Location not found")

    route_step = RouteStep(
        route_id=payload.route_id,
        location_id=payload.location_id,
        step_order=payload.step_order,
    )
    db.add(route_step)

    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=400, detail="Duplicate step_order for this route")

    db.refresh(route_step)
    return route_step


@router.get("/", response_model=list[RouteStepResponse])
def list_route_steps(db: Session = Depends(get_db)):
    return db.query(RouteStep).all()


@router.patch("/{route_step_id}", response_model=RouteStepResponse)
def update_route_step(
    route_step_id: UUID,
    payload: RouteStepUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    route_step = db.query(RouteStep).filter(RouteStep.id == route_step_id).first()
    if not route_step:
        raise HTTPException(status_code=404, detail="Route step not found")

    update_data = payload.model_dump(exclude_unset=True)

    if "route_id" in update_data:
        route = db.query(Route).filter(Route.id == update_data["route_id"]).first()
        if not route:
            raise HTTPException(status_code=404, detail="Route not found")

    if "location_id" in update_data:
        location = db.query(Location).filter(Location.id == update_data["location_id"]).first()
        if not location:
            raise HTTPException(status_code=404, detail="Location not found")

    for field, value in update_data.items():
        setattr(route_step, field, value)

    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=400, detail="Duplicate step_order for this route")

    db.refresh(route_step)
    return route_step