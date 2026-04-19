from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user
from app.models.beacon import Beacon
from app.models.location import Location
from app.models.user import User
from app.schemas.beacon import BeaconCreate, BeaconResponse

router = APIRouter(prefix="/api/v1/beacons", tags=["Beacons"])


@router.post("/", response_model=BeaconResponse, status_code=status.HTTP_201_CREATED)
def create_beacon(
    payload: BeaconCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    location = db.query(Location).filter(Location.id == payload.location_id).first()
    if not location:
        raise HTTPException(status_code=404, detail="Location not found")

    beacon = Beacon(
        uuid=payload.uuid,
        major=payload.major,
        minor=payload.minor,
        name=payload.name,
        location_id=payload.location_id,
        battery_level=payload.battery_level,
        last_seen=payload.last_seen,
    )

    db.add(beacon)
    db.commit()
    db.refresh(beacon)
    return beacon


@router.get("/", response_model=list[BeaconResponse])
def list_beacons(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return db.query(Beacon).all()