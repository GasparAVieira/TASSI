from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user
from app.models.user import User
from app.schemas.notification import NotificationResponse
from app.core.notification_manager import notification_manager
from app.services.notification_service import (
    get_user_notifications,
    mark_notification_as_read,
    dismiss_notification,
    serialize_user_notification,
    create_user_notification_if_not_sent_today,
    test_all_notifications_for_user,
)

router = APIRouter(prefix="/api/v1/notifications", tags=["Notifications"])


@router.get("", response_model=list[NotificationResponse])
def list_notifications(
    unread_only: bool = False,
    include_dismissed: bool = False,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return get_user_notifications(
        db=db,
        user=current_user,
        unread_only=unread_only,
        include_dismissed=include_dismissed,
    )


@router.patch("/{notification_id}/read", response_model=NotificationResponse)
def read_notification(
    notification_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    notification = mark_notification_as_read(
        db=db,
        user=current_user,
        notification_id=notification_id,
    )

    if notification is None:
        raise HTTPException(status_code=404, detail="Notification not found")

    return serialize_user_notification(
        notification,
        current_user.preferred_language,
    )


@router.patch("/{notification_id}/dismiss", response_model=NotificationResponse)
def dismiss_user_notification(
    notification_id: UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    notification = dismiss_notification(
        db=db,
        user=current_user,
        notification_id=notification_id,
    )

    if notification is None:
        raise HTTPException(status_code=404, detail="Notification not found")

    return serialize_user_notification(
        notification,
        current_user.preferred_language,
    )

@router.post("/send-diary-reminder", response_model=NotificationResponse)
async def send_diary_reminder(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    notification = create_user_notification_if_not_sent_today(
        db=db,
        user=current_user,
        template_type="diary_daily_reminder",
    )

    if notification is None:
        raise HTTPException(
            status_code=409,
            detail="Notification already sent today or template not found",
        )

    payload = serialize_user_notification(
        notification,
        current_user.preferred_language,
    )

    await notification_manager.send_to_user(
        user_id=current_user.id,
        payload={
            "event": "notification.created",
            "data": payload,
        },
    )

    return payload

@router.post("/test-all")
async def test_all_notifications(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    notifications = test_all_notifications_for_user(db, current_user)

    language = current_user.preferred_language

    results = []

    for notification in notifications:
        payload = serialize_user_notification(notification, language)

        results.append(payload)

        await notification_manager.send_to_user(
            user_id=current_user.id,
            payload={
                "event": "notification.created",
                "data": payload,
            },
        )

    return {
        "sent": len(results),
        "notifications": results,
    }