from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import require_admin
from app.models.building import Building
from app.models.location import Location
from app.models.room import Room
from app.models.user import User
from app.schemas.room import RoomCreate, RoomResponse, RoomUpdate

router = APIRouter(prefix="/api/v1/rooms", tags=["Rooms"])


@router.post("/", response_model=RoomResponse, status_code=status.HTTP_201_CREATED)
def create_room(
    payload: RoomCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
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
def list_rooms(db: Session = Depends(get_db)):
    return db.query(Room).all()


@router.patch("/{room_id}", response_model=RoomResponse)
def update_room(
    room_id: UUID,
    payload: RoomUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    room = db.query(Room).filter(Room.id == room_id).first()
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")

    update_data = payload.model_dump(exclude_unset=True)

    if "building_id" in update_data:
        building = db.query(Building).filter(Building.id == update_data["building_id"]).first()
        if not building:
            raise HTTPException(status_code=404, detail="Building not found")

    if "location_id" in update_data and update_data["location_id"] is not None:
        location = db.query(Location).filter(Location.id == update_data["location_id"]).first()
        if not location:
            raise HTTPException(status_code=404, detail="Location not found")

    for field, value in update_data.items():
        setattr(room, field, value)

    db.commit()
    db.refresh(room)
    return room


@router.delete("/{room_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_room(
    room_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    room = db.query(Room).filter(Room.id == room_id).first()
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")

    db.delete(room)
    db.commit()
    return None