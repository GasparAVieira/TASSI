from fastapi import APIRouter, Depends, HTTPException, status
from shapely import wkt
from sqlalchemy.orm import Session
from uuid import UUID

from app.database import get_db
from app.dependencies import require_admin
from app.models.building import Building
from app.models.location import Location
from app.models.user import User
from app.schemas.location import LocationCreate, LocationResponse, LocationUpdate

router = APIRouter(prefix="/api/v1/locations", tags=["Locations"])


def serialize_location(location: Location) -> LocationResponse:
    return LocationResponse(
        id=location.id,
        type=location.type,
        name=location.name,
        floor=location.floor,
        local_x=location.local_x,
        local_y=location.local_y,
        description=location.description,
        beacon_uuid=location.beacon_uuid,
        beacon_major=location.beacon_major,
        beacon_minor=location.beacon_minor,
        beacon_battery_level=location.beacon_battery_level,
        model_url=location.model_url,
        model_type=location.model_type,
        created_at=location.created_at,
        updated_at=location.updated_at,
    )


@router.post("/", response_model=LocationResponse, status_code=status.HTTP_201_CREATED)
def create_location(
    payload: LocationCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    location = Location(**payload.model_dump())

    db.add(location)
    db.commit()
    db.refresh(location)

    return serialize_location(location)


@router.get("/", response_model=list[LocationResponse])
def list_locations(db: Session = Depends(get_db)):
    locations = db.query(Location).all()
    return [serialize_location(loc) for loc in locations]


@router.get("/{location_id}", response_model=LocationResponse)
def get_location(location_id: UUID, db: Session = Depends(get_db)):
    location = db.query(Location).filter(Location.id == location_id).first()

    if not location:
        raise HTTPException(status_code=404, detail="Location not found")

    return serialize_location(location)


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

    return serialize_location(location)