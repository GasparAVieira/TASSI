from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.location import Location
from app.models.path import Path
from app.schemas.path import PathCreate, PathResponse

router = APIRouter(prefix="/api/v1/paths", tags=["Paths"])


@router.post("/", response_model=PathResponse, status_code=status.HTTP_201_CREATED)
def create_path(
    payload: PathCreate,
    db: Session = Depends(get_db),
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
        raise HTTPException(
            status_code=400,
            detail="Invalid path: duplicate edge or self loop",
        )

    db.refresh(path)
    return path


@router.get("/", response_model=list[PathResponse])
def list_paths(
    db: Session = Depends(get_db),
):
    return db.query(Path).all()