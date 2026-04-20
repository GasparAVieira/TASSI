from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import require_admin
from app.models.poi_media import PoiMedia
from app.models.point_of_interest import PointOfInterest
from app.models.user import User
from app.schemas.poi_media import PoiMediaCreate, PoiMediaResponse, PoiMediaUpdate

router = APIRouter(prefix="/api/v1/poi-media", tags=["POI Media"])


@router.post("/", response_model=PoiMediaResponse, status_code=status.HTTP_201_CREATED)
def create_poi_media(
    payload: PoiMediaCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    poi = db.query(PointOfInterest).filter(PointOfInterest.id == payload.poi_id).first()
    if not poi:
        raise HTTPException(status_code=404, detail="Point of interest not found")

    media = PoiMedia(
        poi_id=payload.poi_id,
        media_type=payload.media_type,
        file_url=payload.file_url,
        description=payload.description,
    )
    db.add(media)
    db.commit()
    db.refresh(media)
    return media


@router.get("/", response_model=list[PoiMediaResponse])
def list_poi_media(db: Session = Depends(get_db)):
    return db.query(PoiMedia).all()


@router.patch("/{media_id}", response_model=PoiMediaResponse)
def update_poi_media(
    media_id: UUID,
    payload: PoiMediaUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    media = db.query(PoiMedia).filter(PoiMedia.id == media_id).first()
    if not media:
        raise HTTPException(status_code=404, detail="POI media not found")

    update_data = payload.model_dump(exclude_unset=True)

    if "poi_id" in update_data:
        poi = db.query(PointOfInterest).filter(PointOfInterest.id == update_data["poi_id"]).first()
        if not poi:
            raise HTTPException(status_code=404, detail="Point of interest not found")

    for field, value in update_data.items():
        setattr(media, field, value)

    db.commit()
    db.refresh(media)
    return media