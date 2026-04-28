from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query
from jose import JWTError, jwt

from app.core.config import settings
from app.core.notification_manager import notification_manager
from app.database import SessionLocal
from app.models.user import User

router = APIRouter(tags=["Notification Socket"])


@router.websocket("/ws/notifications")
async def notifications_websocket(
    websocket: WebSocket,
    token: str = Query(...),
):
    db = SessionLocal()

    try:
        try:
            payload = jwt.decode(
                token,
                settings.SECRET_KEY,
                algorithms=[settings.ALGORITHM],
            )

            user_id = payload.get("sub")

            if user_id is None:
                await websocket.close(code=1008)
                return

            user = db.query(User).filter(User.id == user_id).first()

            if user is None:
                await websocket.close(code=1008)
                return

        except JWTError:
            await websocket.close(code=1008)
            return

        await notification_manager.connect(user.id, websocket)

        try:
            while True:
                await websocket.receive_text()

        except WebSocketDisconnect:
            notification_manager.disconnect(user.id, websocket)

    finally:
        db.close()