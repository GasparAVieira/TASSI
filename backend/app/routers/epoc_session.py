from uuid import UUID
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user, require_admin
from app.models.epoc_session import EpocSession
from app.models.user import User
from app.schemas.epoc_session import (
    EpocSessionCreate,
    EpocSessionResponse,
    EpocSessionUpdate,
)

router = APIRouter(
    prefix="/api/v1/epoc-sessions",
    tags=["EPOC Sessions"],
)


@router.post("/",response_model=EpocSessionResponse,status_code=status.HTTP_201_CREATED,)
def create_epoc_session(
    payload: EpocSessionCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    session = EpocSession(
        participant_id=current_user.id,
        attention=payload.attention,
        engagement=payload.engagement,
        excitement=payload.excitement,
        interest=payload.interest,
        relaxation=payload.relaxation,
        stress=payload.stress,
        detected_command=payload.detected_command,
        recorded_at=payload.recorded_at or datetime.utcnow(),
    )

    db.add(session)
    db.commit()
    db.refresh(session)

    return session


@router.get("/me",response_model=list[EpocSessionResponse],)
def list_my_epoc_sessions(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return (
        db.query(EpocSession)
        .filter(EpocSession.participant_id == current_user.id)
        .order_by(EpocSession.recorded_at.desc())
        .all()
    )

@router.get("/admin/all",response_model=list[EpocSessionResponse],)
def list_all_epoc_sessions(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    return (
        db.query(EpocSession)
        .order_by(EpocSession.recorded_at.desc())
        .all()
    )


@router.get("/{session_id}",response_model=EpocSessionResponse,)
def get_epoc_session(
    session_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    session = (
        db.query(EpocSession)
        .filter(
            EpocSession.id == session_id,
            EpocSession.participant_id == current_user.id,
        )
        .first()
    )

    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="EPOC session not found",
        )

    return session

@router.put("/{session_id}",response_model=EpocSessionResponse,)
def update_epoc_session(
    session_id: UUID,
    payload: EpocSessionUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    session = (
        db.query(EpocSession)
        .filter(
            EpocSession.id == session_id,
            EpocSession.participant_id == current_user.id,
        )
        .first()
    )

    if not session:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="EPOC session not found",
        )

    update_data = payload.model_dump(exclude_unset=True)

    for field, value in update_data.items():
        setattr(session, field, value)

    db.commit()
    db.refresh(session)

    return session


@router.delete("/{session_id}",status_code=status.HTTP_204_NO_CONTENT,)
def delete_epoc_session(
    session_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    session = (
        db.query(EpocSession)
        .filter(
            EpocSession.id == session_id,
            EpocSession.participant_id == current_user.id,
        )
        .first()
    )
    db.commit()