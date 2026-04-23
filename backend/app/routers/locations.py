from fastapi import APIRouter, Depends, HTTPException, status
from geoalchemy2.shape import from_shape, to_shape
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
    geom_wkt = to_shape(location.geom).wkt if location.geom is not None else None

    return LocationResponse(
        id=location.id,
        building_id=location.building_id,
        type=location.type,
        name=location.name,
        floor=location.floor,
        geom_wkt=geom_wkt,
        local_x=location.local_x,
        local_y=location.local_y,
        description=location.description,
        is_accessible=location.is_accessible,
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
    if payload.building_id is not None:
        building = db.query(Building).filter(Building.id == payload.building_id).first()
        if not building:
            raise HTTPException(status_code=404, detail="Building not found")

    location = Location(
        building_id=payload.building_id,
        type=payload.type,
        name=payload.name,
        floor=payload.floor,
        geom=from_shape(wkt.loads(payload.geom_wkt), srid=4326),
        local_x=payload.local_x,
        local_y=payload.local_y,
        description=payload.description,
        is_accessible=payload.is_accessible,
        model_url=payload.model_url,
        model_type=payload.model_type,
    )

    db.add(location)
    db.commit()
    db.refresh(location)
    return serialize_location(location)


@router.get("/", response_model=list[LocationResponse])
def list_locations(db: Session = Depends(get_db)):
    locations = db.query(Location).all()
    return [serialize_location(location) for location in locations]


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

    if "building_id" in update_data and update_data["building_id"] is not None:
        building = db.query(Building).filter(Building.id == update_data["building_id"]).first()
        if not building:
            raise HTTPException(status_code=404, detail="Building not found")

    if "geom_wkt" in update_data:
        location.geom = from_shape(wkt.loads(update_data["geom_wkt"]), srid=4326)
        update_data.pop("geom_wkt")

    for field, value in update_data.items():
        setattr(location, field, value)

    db.commit()
    db.refresh(location)
    return serialize_location(location)