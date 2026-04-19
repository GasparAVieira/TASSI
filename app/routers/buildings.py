from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import require_admin
from app.models.building import Building
from app.models.user import User
from app.schemas.building import BuildingCreate, BuildingResponse, BuildingUpdate

router = APIRouter(prefix="/api/v1/buildings", tags=["Buildings"])


@router.post("/", response_model=BuildingResponse, status_code=status.HTTP_201_CREATED)
def create_building(
    payload: BuildingCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    building = Building(
        name=payload.name,
        description=payload.description,
    )
    db.add(building)
    db.commit()
    db.refresh(building)
    return building


@router.get("/", response_model=list[BuildingResponse])
def list_buildings(db: Session = Depends(get_db)):
    return db.query(Building).all()


@router.patch("/{building_id}", response_model=BuildingResponse)
def update_building(
    building_id: UUID,
    payload: BuildingUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    building = db.query(Building).filter(Building.id == building_id).first()
    if not building:
        raise HTTPException(status_code=404, detail="Building not found")

    update_data = payload.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(building, field, value)

    db.commit()
    db.refresh(building)
    return building


@router.delete("/{building_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_building(
    building_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    building = db.query(Building).filter(Building.id == building_id).first()
    if not building:
        raise HTTPException(status_code=404, detail="Building not found")

    db.delete(building)
    db.commit()
    return None