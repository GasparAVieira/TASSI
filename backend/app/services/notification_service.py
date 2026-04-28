from datetime import datetime, time, timezone
from uuid import UUID

from sqlalchemy.orm import Session

from app.core.enums import Language
from app.models.diary_entry import DiaryEntry
from app.models.user import User
from app.models.user_notifications import UserNotification
from app.models.notification_templates import NotificationTemplate


def get_start_of_today() -> datetime:
    now = datetime.now(timezone.utc)
    return datetime.combine(now.date(), time.min, tzinfo=timezone.utc)


def user_has_diary_today(db: Session, user: User) -> bool:
    start_of_today = get_start_of_today()

    return (
        db.query(Diary)
        .filter(
            Diary.user_id == user.id,
            Diary.created_at >= start_of_today,
        )
        .first()
        is not None
    )


def get_template_by_type(
    db: Session,
    template_type: str,
) -> NotificationTemplate | None:
    return (
        db.query(NotificationTemplate)
        .filter(
            NotificationTemplate.type == template_type,
            NotificationTemplate.is_active == True,
        )
        .first()
    )


def user_received_template_today(
    db: Session,
    user_id: UUID,
    template_id: UUID,
) -> bool:
    start_of_today = get_start_of_today()

    return (
        db.query(UserNotification)
        .filter(
            UserNotification.user_id == user_id,
            UserNotification.template_id == template_id,
            UserNotification.shown_at >= start_of_today,
        )
        .first()
        is not None
    )


def create_user_notification_if_not_sent_today(
    db: Session,
    user: User,
    template_type: str,
) -> UserNotification | None:
    template = get_template_by_type(db, template_type)

    if template is None:
        return None

    if user_received_template_today(db, user.id, template.id):
        return None

    notification = UserNotification(
        user_id=user.id,
        template_id=template.id,
    )

    db.add(notification)
    db.commit()
    db.refresh(notification)

    return notification


def serialize_user_notification(
    notification: UserNotification,
    language: Language,
) -> dict:
    template = notification.template

    if language == Language.en:
        title = template.title_en or template.title_pt
        message = template.message_en or template.message_pt
    else:
        title = template.title_pt or template.title_en
        message = template.message_pt or template.message_en

    return {
        "id": notification.id,
        "type": template.type,
        "title": title,
        "message": message,
        "priority": template.priority,
        "action": template.action,
        "shown_at": notification.shown_at,
        "read_at": notification.read_at,
        "dismissed_at": notification.dismissed_at,
        "expires_at": notification.expires_at,
    }


def create_diary_reminder_for_user(
    db: Session,
    user: User,
) -> dict | None:
    if user_has_diary_today(db, user):
        return None

    notification = create_user_notification_if_not_sent_today(
        db=db,
        user=user,
        template_type="diary_daily_reminder",
    )

    if notification is None:
        return None

    language = user.preferred_language or Language.pt

    return serialize_user_notification(notification, language)


def get_user_notifications(
    db: Session,
    user: User,
    unread_only: bool = False,
    include_dismissed: bool = False,
):
    query = (
        db.query(UserNotification)
        .join(NotificationTemplate)
        .filter(
            UserNotification.user_id == user.id,
            NotificationTemplate.is_active == True,
        )
    )

    if unread_only:
        query = query.filter(UserNotification.read_at.is_(None))

    if not include_dismissed:
        query = query.filter(UserNotification.dismissed_at.is_(None))

    notifications = query.order_by(UserNotification.shown_at.desc()).all()

    language = user.preferred_language or Language.pt

    return [
        serialize_user_notification(notification, language)
        for notification in notifications
    ]


def mark_notification_as_read(
    db: Session,
    user: User,
    notification_id: UUID,
):
    notification = (
        db.query(UserNotification)
        .filter(
            UserNotification.id == notification_id,
            UserNotification.user_id == user.id,
        )
        .first()
    )

    if notification is None:
        return None

    notification.read_at = datetime.now(timezone.utc)

    db.commit()
    db.refresh(notification)

    return notification


def dismiss_notification(
    db: Session,
    user: User,
    notification_id: UUID,
):
    notification = (
        db.query(UserNotification)
        .filter(
            UserNotification.id == notification_id,
            UserNotification.user_id == user.id,
        )
        .first()
    )

    if notification is None:
        return None

    notification.dismissed_at = datetime.now(timezone.utc)

    db.commit()
    db.refresh(notification)

    return notification