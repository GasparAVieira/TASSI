from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import require_admin
from app.models.location import Location
from app.models.user import User
from app.schemas.location import LocationCreate, LocationResponse, LocationUpdate

router = APIRouter(prefix="/api/v1/locations", tags=["Locations"])


@router.post("/", response_model=LocationResponse, status_code=status.HTTP_201_CREATED)
def create_location(
    payload: LocationCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    location = Location(
        name=payload.name,
        floor=payload.floor,
        x=payload.x,
        y=payload.y,
        description=payload.description,
        model_url=payload.model_url,
        model_type=payload.model_type,
    )
    db.add(location)
    db.commit()
    db.refresh(location)
    return location


@router.get("/", response_model=list[LocationResponse])
def list_locations(db: Session = Depends(get_db)):
    return db.query(Location).all()


@router.patch("/{location_id}", response_model=LocationResponse)
def update_location(
    location_id: UUID,
    payload: LocationUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    location = db.query(Location).filter(Location.id == location_id).first()
    if not location:
        raise HTTPException(status_code=404, detail="Location not found")

    update_data = payload.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(location, field, value)

    db.commit()
    db.refresh(location)
    return location


@router.delete("/{location_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_location(
    location_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    location = db.query(Location).filter(Location.id == location_id).first()
    if not location:
        raise HTTPException(status_code=404, detail="Location not found")

    db.delete(location)
    db.commit()
    return None