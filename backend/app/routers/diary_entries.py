from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.diary_entry import DiaryEntry
from app.schemas.diary_entry import (
    DiaryEntryCreate,
    DiaryEntryResponse,
    DiaryEntryUpdate,
)

router = APIRouter(prefix="/api/v1/diary-entries", tags=["Diary Entries"])


@router.post("/", response_model=DiaryEntryResponse, status_code=status.HTTP_201_CREATED)
def create_diary_entry(payload: DiaryEntryCreate, db: Session = Depends(get_db)):
    entry = DiaryEntry(**payload.model_dump())
    db.add(entry)
    db.commit()
    db.refresh(entry)
    return entry


@router.get("/", response_model=list[DiaryEntryResponse])
def list_diary_entries(db: Session = Depends(get_db)):
    return db.query(DiaryEntry).order_by(DiaryEntry.created_at.desc()).all()


@router.get("/{entry_id}", response_model=DiaryEntryResponse)
def get_diary_entry(entry_id: int, db: Session = Depends(get_db)):
    entry = db.query(DiaryEntry).filter(DiaryEntry.id == entry_id).first()
    if not entry:
        raise HTTPException(status_code=404, detail="Diary entry not found")
    return entry


@router.put("/{entry_id}", response_model=DiaryEntryResponse)
def update_diary_entry(entry_id: int, payload: DiaryEntryUpdate, db: Session = Depends(get_db)):
    entry = db.query(DiaryEntry).filter(DiaryEntry.id == entry_id).first()
    if not entry:
        raise HTTPException(status_code=404, detail="Diary entry not found")

    update_data = payload.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(entry, field, value)

    db.commit()
    db.refresh(entry)
    return entry