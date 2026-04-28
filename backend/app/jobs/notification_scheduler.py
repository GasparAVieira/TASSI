import asyncio

from app.database import SessionLocal
from app.models.user import User
from app.services.notification_service import create_diary_reminder_for_user
from app.core.notification_manager import notification_manager


async def run_diary_notification_check():
    db = SessionLocal()

    try:
        users = db.query(User).all()

        for user in users:
            notification_payload = create_diary_reminder_for_user(db, user)

            if notification_payload is not None:
                await notification_manager.send_to_user(
                    user_id=user.id,
                    payload={
                        "event": "notification.created",
                        "data": notification_payload,
                    },
                )

    finally:
        db.close()


async def notification_scheduler_loop():
    while True:
        await run_diary_notification_check()

        # verifica de hora a hora
        await asyncio.sleep(60 * 60)