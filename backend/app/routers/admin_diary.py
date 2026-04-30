from datetime import datetime
from typing import Annotated, Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session, joinedload

from app.core.enums import DiaryEntryType, Language
from app.core.notification_manager import notification_manager
from app.database import get_db
from app.dependencies import require_admin
from app.models.diary_entry import DiaryEntry
from app.models.diary_entry_comment import DiaryEntryComment
from app.models.user import User
from app.schemas.diary_entry import DiaryEntryListResponse, DiaryEntryResponse
from app.schemas.diary_entry_comment import (
    DiaryEntryCommentCreate,
    DiaryEntryCommentResponse,
    DiaryEntryCommentUpdate,
)
from app.services.notification_service import create_user_notification, serialize_user_notification

router = APIRouter(
    prefix="/api/v1/admin/diary-entries",
    tags=["Admin - Diary Entries"],
    dependencies=[Depends(require_admin)],
)


@router.get("/", response_model=DiaryEntryListResponse)
def list_diary_entries(
    db: Session = Depends(get_db),
    participant_id: Annotated[Optional[UUID], Query()] = None,
    entry_type: Annotated[Optional[DiaryEntryType], Query()] = None,
    recorded_from: Annotated[Optional[datetime], Query()] = None,
    recorded_to: Annotated[Optional[datetime], Query()] = None,
    has_comment: Annotated[Optional[bool], Query()] = None,
    search: Annotated[Optional[str], Query()] = None,
    limit: Annotated[int, Query(ge=1, le=100)] = 20,
    offset: Annotated[int, Query(ge=0)] = 0,
):
    query = db.query(DiaryEntry)

    if participant_id is not None:
        query = query.filter(DiaryEntry.participant_id == participant_id)
    if entry_type is not None:
        query = query.filter(DiaryEntry.entry_type == entry_type.value)
    if recorded_from is not None:
        query = query.filter(DiaryEntry.recorded_at >= recorded_from)
    if recorded_to is not None:
        query = query.filter(DiaryEntry.recorded_at <= recorded_to)
    if has_comment is True:
        query = query.filter(DiaryEntry.comments.any())
    elif has_comment is False:
        query = query.filter(~DiaryEntry.comments.any())
    if search is not None:
        query = query.filter(DiaryEntry.body.ilike(f"%{search}%"))

    total = query.count()
    items = (
        query
        .options(
            joinedload(DiaryEntry.media_items),
            joinedload(DiaryEntry.comments).joinedload(DiaryEntryComment.author),
        )
        .order_by(DiaryEntry.recorded_at.desc())
        .offset(offset)
        .limit(limit)
        .all()
    )

    return DiaryEntryListResponse(items=items, total=total, limit=limit, offset=offset)


@router.get("/{entry_id}", response_model=DiaryEntryResponse)
def get_diary_entry(
    entry_id: UUID,
    db: Session = Depends(get_db),
):
    entry = (
        db.query(DiaryEntry)
        .options(
            joinedload(DiaryEntry.media_items),
            joinedload(DiaryEntry.comments).joinedload(DiaryEntryComment.author),
        )
        .filter(DiaryEntry.id == entry_id)
        .first()
    )

    if not entry:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Diary entry not found")

    return entry


@router.post("/{entry_id}/comments", response_model=DiaryEntryCommentResponse, status_code=status.HTTP_201_CREATED)
async def create_entry_comment(
    entry_id: UUID,
    payload: DiaryEntryCommentCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    entry = (
        db.query(DiaryEntry)
        .options(joinedload(DiaryEntry.participant))
        .filter(DiaryEntry.id == entry_id)
        .first()
    )
    if not entry:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Diary entry not found")

    comment = DiaryEntryComment(
        entry_id=entry_id,
        author_id=current_user.id,
        body=payload.body,
    )
    db.add(comment)
    db.commit()
    db.refresh(comment)

    participant = entry.participant
    notification = create_user_notification(db, participant, "diary_admin_response")
    if notification is not None:
        language = participant.preferred_language or Language.pt
        await notification_manager.send_to_user(
            participant.id,
            {"event": "notification.created", "data": serialize_user_notification(notification, language)},
        )

    return (
        db.query(DiaryEntryComment)
        .options(joinedload(DiaryEntryComment.author))
        .filter(DiaryEntryComment.id == comment.id)
        .first()
    )


@router.patch("/comments/{comment_id}", response_model=DiaryEntryCommentResponse)
def update_entry_comment(
    comment_id: UUID,
    payload: DiaryEntryCommentUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    comment = (
        db.query(DiaryEntryComment)
        .filter(DiaryEntryComment.id == comment_id)
        .first()
    )

    if not comment:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Comment not found")

    if current_user.role != "superadmin" and comment.author_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized to edit this comment")

    if payload.body is not None:
        comment.body = payload.body

    db.commit()

    return (
        db.query(DiaryEntryComment)
        .options(joinedload(DiaryEntryComment.author))
        .filter(DiaryEntryComment.id == comment_id)
        .first()
    )


@router.delete("/comments/{comment_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_entry_comment(
    comment_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    comment = (
        db.query(DiaryEntryComment)
        .filter(DiaryEntryComment.id == comment_id)
        .first()
    )

    if not comment:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Comment not found")

    if current_user.role != "superadmin" and comment.author_id != current_user.id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not authorized to delete this comment")

    db.delete(comment)
    db.commit()
