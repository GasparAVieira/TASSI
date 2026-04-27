from fastapi import APIRouter, Depends, HTTPException, status
from geoalchemy2.shape import from_shape, to_shape
from shapely import wkt
from sqlalchemy.orm import Session
from uuid import UUID

from app.database import get_db
from app.dependencies import require_admin
from app.models.building import Building
from app.models.user import User
from app.schemas.building import BuildingCreate, BuildingResponse, BuildingUpdate

router = APIRouter(prefix="/api/v1/buildings", tags=["Buildings"])


def serialize_building(building: Building) -> BuildingResponse:
    footprint_wkt = None
    if building.footprint is not None:
        footprint_wkt = to_shape(building.footprint).wkt

    return BuildingResponse(
        id=building.id,
        code=building.code,
        name=building.name,
        description=building.description,
        footprint_wkt=footprint_wkt,
        created_at=building.created_at,
        updated_at=building.updated_at,
    )


@router.post("/", response_model=BuildingResponse, status_code=status.HTTP_201_CREATED)
def create_building(
    payload: BuildingCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    building = Building(**payload.model_dump())

    db.add(building)
    db.commit()
    db.refresh(building)

    return building


@router.get("/", response_model=list[BuildingResponse])
def list_buildings(db: Session = Depends(get_db)):
    return db.query(Building).all()


@router.get("/{building_id}", response_model=BuildingResponse)
def get_building(building_id: UUID, db: Session = Depends(get_db)):
    building = db.query(Building).filter(Building.id == building_id).first()

    if not building:
        raise HTTPException(status_code=404, detail="Building not found")

    return building


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