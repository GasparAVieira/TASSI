from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import require_admin
from app.models.faq import Faq
from app.models.user import User
from app.schemas.faq import FaqCreate, FaqResponse, FaqUpdate

router = APIRouter(prefix="/api/v1/faqs", tags=["FAQs"])


@router.post("/", response_model=FaqResponse, status_code=status.HTTP_201_CREATED)
def create_faq(
    payload: FaqCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    faq = Faq(
        question=payload.question,
        answer=payload.answer,
        category=payload.category,
        display_order=payload.display_order,
        is_visible=payload.is_visible,
    )
    db.add(faq)
    db.commit()
    db.refresh(faq)
    return faq


@router.get("/", response_model=list[FaqResponse])
def list_faqs(db: Session = Depends(get_db)):
    return db.query(Faq).all()


@router.patch("/{faq_id}", response_model=FaqResponse)
def update_faq(
    faq_id: UUID,
    payload: FaqUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    faq = db.query(Faq).filter(Faq.id == faq_id).first()
    if not faq:
        raise HTTPException(status_code=404, detail="FAQ not found")

    update_data = payload.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(faq, field, value)

    db.commit()
    db.refresh(faq)
    return faq