from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from geoalchemy2.elements import WKTElement
from sqlalchemy.orm import Session, joinedload

from app.dependencies import get_current_user
from app.database import get_db
from app.models.diary_entry import DiaryEntry
from app.models.diary_media import DiaryMedia
from app.models.user import User
from app.schemas.diary_entry import (
    DiaryEntryCreate,
    DiaryEntryResponse,
    DiaryEntryUpdate,
)

router = APIRouter(prefix="/api/v1/diary-entries", tags=["Diary Entries"])


@router.post("/",response_model=DiaryEntryResponse,status_code=status.HTTP_201_CREATED,)
def create_diary_entry(payload: DiaryEntryCreate,db: Session = Depends(get_db),current_user: User = Depends(get_current_user),):
    #validate_diary_entry_payload(payload)

    entry = DiaryEntry(
        participant_id=current_user.id,
        entry_type=payload.entry_type,
        body=payload.body,
        duration_sec=payload.duration_sec,
        recorded_at=payload.recorded_at,
        geom=build_geom(payload.latitude, payload.longitude),
        location_id=payload.location_id,
        building_id=payload.building_id,
        beacon_id=payload.beacon_id,
        context_notes=payload.context_notes,
        is_synced=payload.is_synced,
    )

    db.add(entry)
    db.flush()

    for media_item in payload.media_items:
        db.add(
            DiaryMedia(
                entry_id=entry.id,
                media_type=media_item.media_type,
                url=media_item.url,
                duration_sec=media_item.duration_sec,
                transcription=media_item.transcription,
                language=media_item.language,
            )
        )

    db.commit()

    created_entry = (
        db.query(DiaryEntry)
        .options(joinedload(DiaryEntry.media_items))
        .filter(DiaryEntry.id == entry.id)
        .first()
    )

    return created_entry

@router.get("/me", response_model=list[DiaryEntryResponse])
def list_my_diary_entries(db: Session = Depends(get_db),current_user: User = Depends(get_current_user),):
    return (
        db.query(DiaryEntry)
        .options(joinedload(DiaryEntry.media_items))
        .filter(DiaryEntry.participant_id == current_user.id)
        .order_by(DiaryEntry.recorded_at.desc())
        .all()
    )

@router.get("/", response_model=list[DiaryEntryResponse])
def list_diary_entries(db: Session = Depends(get_db)):
    return db.query(DiaryEntry).order_by(DiaryEntry.created_at.desc()).all()

@router.get("/{entry_id}", response_model=DiaryEntryResponse)
def get_diary_entry(entry_id: UUID,db: Session = Depends(get_db),current_user: User = Depends(get_current_user),):
    entry = (
        db.query(DiaryEntry)
        .options(joinedload(DiaryEntry.media_items))
        .filter(
            DiaryEntry.id == entry_id,
            DiaryEntry.participant_id == current_user.id,
        )
        .first()
    )

    if not entry:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,detail="Diary entry not found",)

    return entry


@router.put("/{entry_id}", response_model=DiaryEntryResponse)
def update_diary_entry(entry_id: UUID,payload: DiaryEntryUpdate,db: Session = Depends(get_db),current_user: User = Depends(get_current_user),):
    entry = (
        db.query(DiaryEntry)
        .options(joinedload(DiaryEntry.media_items))
        .filter(
            DiaryEntry.id == entry_id,
            DiaryEntry.participant_id == current_user.id,
        )
        .first()
    )

    if not entry:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,detail="Diary entry not found",)

    update_data = payload.model_dump(exclude_unset=True)

    latitude = update_data.pop("latitude", None) if "latitude" in update_data else None
    longitude = update_data.pop("longitude", None) if "longitude" in update_data else None

    for field, value in update_data.items():
        setattr(entry, field, value)

    if "latitude" in payload.model_fields_set or "longitude" in payload.model_fields_set:
        entry.geom = build_geom(latitude, longitude)

    db.commit()
    db.refresh(entry)

    updated_entry = (
        db.query(DiaryEntry)
        .options(joinedload(DiaryEntry.media_items))
        .filter(DiaryEntry.id == entry.id)
        .first()
    )

    return updated_entry


#def validate_diary_entry_payload(payload: DiaryEntryCreate) -> None:
    if payload.entry_type == "text" and not payload.body:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST,detail="Text entries require body",)
    
    if payload.entry_type in {"audio", "image", "video"} and not payload.media_items:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST,detail="Media entries require at least one media item",)

    for media_item in payload.media_items:
        if payload.entry_type == "text":
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST,detail="Text entries cannot include media items",)

        if payload.entry_type == "audio" and media_item.media_type != "audio":
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST,detail="Audio entry requires audio media",)

        if payload.entry_type == "image" and media_item.media_type != "image":
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST,detail="Image entry requires image media",)

        if payload.entry_type == "video" and media_item.media_type != "video":
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST,detail="Video entry requires video media",)


def build_geom(latitude: float | None, longitude: float | None):
    if latitude is None or longitude is None:
        return None

    return WKTElement(f"POINT({longitude} {latitude})",srid=4326,)