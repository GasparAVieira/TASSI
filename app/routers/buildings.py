from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user
from app.models.building import Building
from app.models.user import User
from app.schemas.building import BuildingCreate, BuildingResponse

router = APIRouter(prefix="/api/v1/buildings", tags=["Buildings"])


@router.post("/", response_model=BuildingResponse, status_code=status.HTTP_201_CREATED)
def create_building(
    payload: BuildingCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
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
def list_buildings(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return db.query(Building).all()