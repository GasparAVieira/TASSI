import asyncio

from app.database import SessionLocal
from app.models.user import User
from app.services.notification_service import run_all_notification_rules
from app.core.notification_manager import notification_manager


async def run_notification_checks():
    db = SessionLocal()

    try:
        users = db.query(User).all()

        for user in users:
            results = run_all_notification_rules(db, user)

            for payload in results:
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
        await run_notification_checks()

        # corre de hora a hora
        await asyncio.sleep(10)