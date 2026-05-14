from datetime import datetime
from typing import Annotated, Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session, joinedload

from app.core.enums import DiaryEntryType
from app.dependencies import get_current_user
from app.database import get_db
from app.models.diary_entry import DiaryEntry
from app.models.diary_entry_comment import DiaryEntryComment
from app.models.diary_media import DiaryMedia
from app.models.user import User
from app.schemas.diary_entry import (
    DiaryEntryCreate,
    DiaryEntryListResponse,
    DiaryEntryResponse,
    DiaryEntryUpdate,
)
from app.schemas.diary_entry_comment import (
    DiaryEntryCommentCreate,
    DiaryEntryCommentResponse,
)

router = APIRouter(prefix="/api/v1/diary-entries",tags=["Diary Entries"],)

@router.post("/",response_model=DiaryEntryResponse,status_code=status.HTTP_201_CREATED,)
def create_diary_entry(payload: DiaryEntryCreate,db: Session = Depends(get_db),current_user: User = Depends(get_current_user),):
    validate_diary_entry_payload(payload)

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
        .options(joinedload(DiaryEntry.media_items), joinedload(DiaryEntry.comments).joinedload(DiaryEntryComment.author))
        .filter(DiaryEntry.id == entry.id)
        .first()
    )

    return created_entry


@router.get("/me", response_model=DiaryEntryListResponse)
def list_my_diary_entries(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
    limit: Annotated[int, Query(ge=1, le=100)] = 20,
    offset: Annotated[int, Query(ge=0)] = 0,
    entry_type: Annotated[Optional[DiaryEntryType], Query()] = None,
    recorded_from: Annotated[Optional[datetime], Query()] = None,
    recorded_to: Annotated[Optional[datetime], Query()] = None,
):
    query = db.query(DiaryEntry).filter(DiaryEntry.participant_id == current_user.id)

    if entry_type is not None:
        query = query.filter(DiaryEntry.entry_type == entry_type.value)
    if recorded_from is not None:
        query = query.filter(DiaryEntry.recorded_at >= recorded_from)
    if recorded_to is not None:
        query = query.filter(DiaryEntry.recorded_at <= recorded_to)

    total = query.count()
    items = (
        query
        .options(joinedload(DiaryEntry.media_items), joinedload(DiaryEntry.comments).joinedload(DiaryEntryComment.author))
        .order_by(DiaryEntry.recorded_at.desc())
        .offset(offset)
        .limit(limit)
        .all()
    )

    return DiaryEntryListResponse(items=items, total=total, limit=limit, offset=offset)


@router.get("/{entry_id}",response_model=DiaryEntryResponse,)
def get_diary_entry(entry_id: UUID,db: Session = Depends(get_db),current_user: User = Depends(get_current_user),):
    entry = (
        db.query(DiaryEntry)
        .options(joinedload(DiaryEntry.media_items), joinedload(DiaryEntry.comments).joinedload(DiaryEntryComment.author))
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
        .options(
            joinedload(DiaryEntry.media_items),
            joinedload(DiaryEntry.comments).joinedload(DiaryEntryComment.author),
        )
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
    update_data.pop("media_items", None)

    for field, value in update_data.items():
        setattr(entry, field, value)

    if payload.media_items is not None:
        entry.media_items.clear()
        for item in payload.media_items:
            entry.media_items.append(DiaryMedia(
                entry_id=entry.id,
                media_type=item.media_type,
                url=item.url,
                duration_sec=item.duration_sec,
                transcription=item.transcription,
                language=item.language,
            ))

    _validate_entry_state(entry.entry_type, entry.body, entry.media_items)

    db.commit()

    return (
        db.query(DiaryEntry)
        .options(
            joinedload(DiaryEntry.media_items),
            joinedload(DiaryEntry.comments).joinedload(DiaryEntryComment.author),
        )
        .filter(DiaryEntry.id == entry_id)
        .first()
    )

@router.delete("/{entry_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_diary_entry(
    entry_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    entry = (
        db.query(DiaryEntry)
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

    db.delete(entry)
    db.commit()


@router.post(
    "/{entry_id}/comments",
    response_model=DiaryEntryCommentResponse,
    status_code=status.HTTP_201_CREATED,
)
def create_entry_comment(
    entry_id: UUID,
    payload: DiaryEntryCommentCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    User-facing comment creation.

    Only the entry's owner (participant) can post here — this is the
    "reply in your own thread" path that lets a diary author respond
    to an admin reply. Admin-side comment creation continues to live
    under /api/v1/admin/diary-entries/... and is gated by require_admin.
    """
    entry = (
        db.query(DiaryEntry)
        .filter(DiaryEntry.id == entry_id)
        .first()
    )
    if entry is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Diary entry not found",
        )
    if entry.participant_id != current_user.id:
        # Don't leak existence to non-owners; mirror the 404 we'd return
        # for an unknown id.
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Diary entry not found",
        )

    comment = DiaryEntryComment(
        entry_id=entry.id,
        author_id=current_user.id,
        body=payload.body,
    )
    db.add(comment)
    db.commit()

    # Re-fetch with the author summary so the response matches the
    # shape the Flutter mapper expects (author.full_name + author.role).
    created = (
        db.query(DiaryEntryComment)
        .options(joinedload(DiaryEntryComment.author))
        .filter(DiaryEntryComment.id == comment.id)
        .first()
    )
    return created


def validate_diary_entry_payload(payload: DiaryEntryCreate) -> None:
    _validate_entry_state(payload.entry_type, payload.body, payload.media_items)


def _validate_entry_state(entry_type: str, body, media_items) -> None:
    # Text entries must have a body and nothing else attached. Adding
    # media would mean the entry's primary content is media, not text —
    # in that case the client should pick an image/audio/video entry_type.
    if entry_type == "text":
        if not body:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Text entries require body",
            )
        if media_items:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Text entries cannot include media items",
            )

    # Media entries must carry at least one attachment, but the kinds
    # may be mixed: a "video" entry can include images alongside the
    # video (e.g. a video diary with screenshots, a photo essay with
    # one clip). entry_type is now a primary-kind hint for filtering,
    # not a strict constraint on the items.
    if entry_type in {"audio", "image", "video"}:
        if not media_items:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Media entries require at least one media item",
            )