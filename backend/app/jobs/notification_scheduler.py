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
            payload = create_diary_reminder_for_user(db, user)

            if payload:
                await notification_manager.send_to_user(
                    user.id,
                    {
                        "event": "notification.created",
                        "data": payload,
                    },
                )

    finally:
        db.close()


async def notification_scheduler_loop():
    while True:
        await run_diary_notification_check()

        # corre de hora a hora
        await asyncio.sleep(30)