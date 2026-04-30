from sqlalchemy.orm import Session

from datetime import datetime, timedelta, timezone
from app.models.diary_entry import DiaryEntry
from app.models.epoc_session import EpocSession

from app.models.user import User
from app.notifications.registry import register_rule
from app.services.notification_service import (
    user_has_diary_today,
    create_user_notification_if_not_sent_today,
    serialize_user_notification,
)
from app.core.enums import Language

STRESS_THRESHOLD = 0.75

@register_rule
def diary_daily_reminder(db: Session, user: User):
    if user_has_diary_today(db, user):
        return None

    notification = create_user_notification_if_not_sent_today(
        db=db,
        user=user,
        template_type="diary_daily_reminder",
    )

    if not notification:
        return None

    return serialize_user_notification(notification, user.preferred_language or Language.pt)

@register_rule
def diary_admin_response(db: Session, user: User):
    notification = create_user_notification_if_not_sent_today(
        db=db,
        user=user,
        template_type="diary_admin_response",
    )

    if not notification:
        return None

    return serialize_user_notification(notification, user.preferred_language or Language.pt)

@register_rule
def inactivity_reminder(db: Session, user: User):
    limit = datetime.now(timezone.utc) - timedelta(days=3)

    recent_activity = (
        db.query(DiaryEntry)
        .filter(
            DiaryEntry.participant_id == user.id,
            DiaryEntry.recorded_at >= limit,
        )
        .first()
    )

    if recent_activity:
        return None

    notification = create_user_notification_if_not_sent_today(
        db=db,
        user=user,
        template_type="inactivity_reminder",
    )

    if not notification:
        return None

    return serialize_user_notification(notification, user.preferred_language or Language.pt)

@register_rule
def welcome_user(db: Session, user: User):
    from datetime import datetime, timezone

    # só no dia de criação (ou fallback simples)
    if user.created_at.date() != datetime.now(timezone.utc).date():
        return None

    notification = create_user_notification_if_not_sent_today(
        db,
        user,
        "welcome_user",
    )

    if not notification:
        return None

    return serialize_user_notification(notification, user.preferred_language or Language.pt)

@register_rule
def weekly_summary(db: Session, user: User):
    from datetime import datetime, timedelta, timezone
    from app.models.diary_entry import DiaryEntry

    last_week = datetime.now(timezone.utc) - timedelta(days=7)

    entries = (
        db.query(DiaryEntry)
        .filter(
            DiaryEntry.participant_id == user.id,
            DiaryEntry.recorded_at >= last_week,
        )
        .count()
    )

    if entries == 0:
        return None

    notification = create_user_notification_if_not_sent_today(
        db,
        user,
        "weekly_summary",
    )

    if not notification:
        return None

    return serialize_user_notification(notification, user.preferred_language or Language.pt)

@register_rule
def profile_incomplete(db: Session, user: User):
    if user.phone and user.bio:
        return None

    notification = create_user_notification_if_not_sent_today(
        db,
        user,
        "profile_incomplete",
    )

    if not notification:
        return None

    return serialize_user_notification(notification, user.preferred_language or Language.pt)

@register_rule
def check_stress_alert(db: Session, user: User):
    latest_session = (
        db.query(EpocSession)
        .filter(EpocSession.participant_id == user.id)
        .order_by(EpocSession.recorded_at.desc())
        .first()
    )

    if not latest_session or latest_session.stress is None:
        return None

    if latest_session.stress < STRESS_THRESHOLD:
        return None

    notification = create_user_notification_if_not_sent_today(
        db=db,
        user=user,
        template_type="stress_alert",
    )

    if not notification:
        return None

    language = user.preferred_language or Language.pt

    return serialize_user_notification(notification, language)