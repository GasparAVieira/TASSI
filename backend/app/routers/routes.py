from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import require_admin
from app.models.route import Route
from app.models.user import User
from app.schemas.route import RouteCreate, RouteResponse, RouteUpdate

router = APIRouter(prefix="/api/v1/routes", tags=["Routes"])


@router.post("/", response_model=RouteResponse, status_code=status.HTTP_201_CREATED)
def create_route(
    payload: RouteCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    route = Route(
        name=payload.name,
        description=payload.description,
    )
    db.add(route)
    db.commit()
    db.refresh(route)
    return route


@router.get("/", response_model=list[RouteResponse])
def list_routes(db: Session = Depends(get_db)):
    return db.query(Route).all()


@router.patch("/{route_id}", response_model=RouteResponse)
def update_route(
    route_id: UUID,
    payload: RouteUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin),
):
    route = db.query(Route).filter(Route.id == route_id).first()
    if not route:
        raise HTTPException(status_code=404, detail="Route not found")

    update_data = payload.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(route, field, value)

    db.commit()
    db.refresh(route)
    return route