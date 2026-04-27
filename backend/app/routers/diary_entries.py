from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
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

router = APIRouter(prefix="/api/v1/diary-entries",tags=["Diary Entries"],)

@router.post("/",response_model=DiaryEntryResponse,status_code=status.HTTP_201_CREATED,)
def create_diary_entry(payload: DiaryEntryCreate,db: Session = Depends(get_db),current_user: User = Depends(get_current_user),):
    #validate_diary_entry_payload(payload)

    entry = DiaryEntry(
        participant_id=current_user.id,
        entry_type=payload.entry_type,
        body=payload.body,
        duration_sec=payload.duration_sec,
        recorded_at=payload.recorded_at,
        location_id=payload.location_id,
        building_id=payload.building_id,
        context_notes=payload.context_notes,
        is_synced=payload.is_synced,
    )

    db.add(entry)
    db.flush()

    for media_item in payload.media_items:
        media = DiaryMedia(
            entry_id=entry.id,
            media_type=media_item.media_type,
            url=media_item.url,
            duration_sec=media_item.duration_sec,
            transcription=media_item.transcription,
            language=media_item.language,
        )
        db.add(media)

    db.commit()

    created_entry = (
        db.query(DiaryEntry)
        .options(joinedload(DiaryEntry.media_items))
        .filter(DiaryEntry.id == entry.id)
        .first()
    )

    return created_entry


@router.get("/me",response_model=list[DiaryEntryResponse],)
def list_my_diary_entries(db: Session = Depends(get_db),current_user: User = Depends(get_current_user),):
    return (
        db.query(DiaryEntry)
        .options(joinedload(DiaryEntry.media_items))
        .filter(DiaryEntry.participant_id == current_user.id)
        .order_by(DiaryEntry.recorded_at.desc())
        .all()
    )


@router.get("/{entry_id}",response_model=DiaryEntryResponse,)
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
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Diary entry not found",
        )

    return entry


@router.put("/{entry_id}",response_model=DiaryEntryResponse,)
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
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Diary entry not found",
        )

    update_data = payload.model_dump(exclude_unset=True)

    for field, value in update_data.items():
        setattr(entry, field, value)

    db.commit()
    db.refresh(entry)

    updated_entry = (
        db.query(DiaryEntry)
        .options(joinedload(DiaryEntry.media_items))
        .filter(DiaryEntry.id == entry.id)
        .first()
    )

    return updated_entry

def validate_diary_entry_payload(payload: DiaryEntryCreate) -> None:
    if payload.entry_type == "text":
        if not payload.body:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Text entries require body",
            )

        if payload.media_items:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Text entries cannot include media items",
            )

    if payload.entry_type in {"audio", "image", "video"}:
        if not payload.media_items:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Media entries require at least one media item",
            )

        for media_item in payload.media_items:
            if payload.entry_type == "audio" and media_item.media_type != "audio":
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Audio entry requires audio media",
                )

            if payload.entry_type == "image" and media_item.media_type != "image":
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Image entry requires image media",
                )

            if payload.entry_type == "video" and media_item.media_type != "video":
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Video entry requires video media",
                )