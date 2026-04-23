from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from uuid import UUID

from app.database import get_db
from app.dependencies import require_admin
from app.models.beacon import Beacon
from app.models.location import Location
from app.models.user import User
from app.schemas.beacon import BeaconCreate, BeaconResponse, BeaconUpdate

router = APIRouter(prefix="/api/v1/beacons", tags=["Beacons"])


@router.post("/", response_model=BeaconResponse, status_code=status.HTTP_201_CREATED)
def create_beacon(
    payload: BeaconCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    if payload.location_id is not None:
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
def list_beacons(db: Session = Depends(get_db)):
    return db.query(Beacon).all()


@router.get("/{beacon_id}", response_model=BeaconResponse)
def get_beacon(beacon_id: UUID, db: Session = Depends(get_db)):
    beacon = db.query(Beacon).filter(Beacon.id == beacon_id).first()
    if not beacon:
        raise HTTPException(status_code=404, detail="Beacon not found")
    return beacon


@router.patch("/{beacon_id}", response_model=BeaconResponse)
def update_beacon(
    beacon_id: UUID,
    payload: BeaconUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    beacon = db.query(Beacon).filter(Beacon.id == beacon_id).first()
    if not beacon:
        raise HTTPException(status_code=404, detail="Beacon not found")

    update_data = payload.model_dump(exclude_unset=True)

    if "location_id" in update_data and update_data["location_id"] is not None:
        location = db.query(Location).filter(Location.id == update_data["location_id"]).first()
        if not location:
            raise HTTPException(status_code=404, detail="Location not found")

    for field, value in update_data.items():
        setattr(beacon, field, value)

    db.commit()
    db.refresh(beacon)
    return beacon