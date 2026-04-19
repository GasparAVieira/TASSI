from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.building import Building
from app.models.location import Location
from app.models.room import Room
from app.schemas.room import RoomCreate, RoomResponse

router = APIRouter(prefix="/api/v1/rooms", tags=["Rooms"])


@router.post("/", response_model=RoomResponse, status_code=status.HTTP_201_CREATED)
def create_room(
    payload: RoomCreate,
    db: Session = Depends(get_db),
):
    building = db.query(Building).filter(Building.id == payload.building_id).first()
    if not building:
        raise HTTPException(status_code=404, detail="Building not found")

    if payload.location_id:
        location = db.query(Location).filter(Location.id == payload.location_id).first()
        if not location:
            raise HTTPException(status_code=404, detail="Location not found")

    room = Room(
        building_id=payload.building_id,
        location_id=payload.location_id,
        name=payload.name,
        floor=payload.floor,
        is_accessible=payload.is_accessible,
        x=payload.x,
        y=payload.y,
    )

    db.add(room)
    db.commit()
    db.refresh(room)
    return room


@router.get("/", response_model=list[RoomResponse])
def list_rooms(
    db: Session = Depends(get_db),
):
    return db.query(Room).all()