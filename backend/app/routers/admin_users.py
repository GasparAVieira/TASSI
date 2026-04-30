from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import require_superadmin
from app.models.user import User
from app.schemas.user import RoleUpdate, UserResponse

router = APIRouter(
    prefix="/api/v1/admin/users",
    tags=["Admin - Users"],
    dependencies=[Depends(require_superadmin)],
)


@router.patch("/{user_id}/role", response_model=UserResponse)
def update_user_role(
    user_id: UUID,
    payload: RoleUpdate,
    db: Session = Depends(get_db),
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    user.role = payload.role
    db.commit()
    db.refresh(user)
    return user
