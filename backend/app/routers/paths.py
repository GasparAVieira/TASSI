from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import require_admin
from app.models.location import Location
from app.models.path import Path
from app.models.user import User
from app.schemas.path import PathCreate, PathResponse, PathUpdate

router = APIRouter(prefix="/api/v1/paths", tags=["Paths"])


@router.post("/", response_model=PathResponse, status_code=status.HTTP_201_CREATED)
def create_path(
    payload: PathCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    from_location = db.query(Location).filter(Location.id == payload.from_location).first()
    if not from_location:
        raise HTTPException(status_code=404, detail="From location not found")

    to_location = db.query(Location).filter(Location.id == payload.to_location).first()
    if not to_location:
        raise HTTPException(status_code=404, detail="To location not found")

    path = Path(
        from_location=payload.from_location,
        to_location=payload.to_location,
        distance=payload.distance,
        direction=payload.direction,
        is_accessible=payload.is_accessible,
    )

    db.add(path)

    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=400, detail="Invalid path: duplicate edge or self loop")

    db.refresh(path)
    return path


@router.get("/", response_model=list[PathResponse])
def list_paths(db: Session = Depends(get_db)):
    return db.query(Path).all()


@router.patch("/{path_id}", response_model=PathResponse)
def update_path(
    path_id: UUID,
    payload: PathUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    path = db.query(Path).filter(Path.id == path_id).first()
    if not path:
        raise HTTPException(status_code=404, detail="Path not found")

    update_data = payload.model_dump(exclude_unset=True)

    if "from_location" in update_data:
        from_location = db.query(Location).filter(Location.id == update_data["from_location"]).first()
        if not from_location:
            raise HTTPException(status_code=404, detail="From location not found")

    if "to_location" in update_data:
        to_location = db.query(Location).filter(Location.id == update_data["to_location"]).first()
        if not to_location:
            raise HTTPException(status_code=404, detail="To location not found")

    for field, value in update_data.items():
        setattr(path, field, value)

    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=400, detail="Invalid path: duplicate edge or self loop")

    db.refresh(path)
    return path