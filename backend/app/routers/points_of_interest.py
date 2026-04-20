from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import require_admin
from app.models.location import Location
from app.models.point_of_interest import PointOfInterest
from app.models.user import User
from app.schemas.point_of_interest import (
    PointOfInterestCreate,
    PointOfInterestResponse,
    PointOfInterestUpdate,
)

router = APIRouter(prefix="/api/v1/points-of-interest", tags=["Points of Interest"])


@router.post("/", response_model=PointOfInterestResponse, status_code=status.HTTP_201_CREATED)
def create_point_of_interest(
    payload: PointOfInterestCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    location = db.query(Location).filter(Location.id == payload.location_id).first()
    if not location:
        raise HTTPException(status_code=404, detail="Location not found")

    poi = PointOfInterest(
        location_id=payload.location_id,
        name=payload.name,
        description=payload.description,
        category=payload.category,
        is_visible=payload.is_visible,
    )
    db.add(poi)
    db.commit()
    db.refresh(poi)
    return poi


@router.get("/", response_model=list[PointOfInterestResponse])
def list_points_of_interest(db: Session = Depends(get_db)):
    return db.query(PointOfInterest).all()


@router.patch("/{poi_id}", response_model=PointOfInterestResponse)
def update_point_of_interest(
    poi_id: UUID,
    payload: PointOfInterestUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    poi = db.query(PointOfInterest).filter(PointOfInterest.id == poi_id).first()
    if not poi:
        raise HTTPException(status_code=404, detail="Point of interest not found")

    update_data = payload.model_dump(exclude_unset=True)

    if "location_id" in update_data:
        location = db.query(Location).filter(Location.id == update_data["location_id"]).first()
        if not location:
            raise HTTPException(status_code=404, detail="Location not found")

    for field, value in update_data.items():
        setattr(poi, field, value)

    db.commit()
    db.refresh(poi)
    return poi