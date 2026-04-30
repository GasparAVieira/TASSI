"""
One-shot database seed script.

Run from the backend/ directory:
    python seed.py

Idempotent: skips rows whose `type` already exists.
"""

from app.database import SessionLocal
from app.models.notification_templates import NotificationTemplate


TEMPLATES = [
    {
        "type": "diary_daily_reminder",
        "title_pt": "Não te esqueças do teu diário",
        "message_pt": "Ainda não registaste o teu diário hoje. Partilha como te sentes!",
        "title_en": "Don't forget your diary",
        "message_en": "You haven't logged your diary today. Share how you feel!",
        "priority": "normal",
        "action": "open_diary",
    },
    {
        "type": "diary_admin_response",
        "title_pt": "Nova resposta ao teu diário",
        "message_pt": "Um administrador respondeu a uma das tuas entradas do diário.",
        "title_en": "New reply on your diary",
        "message_en": "An administrator has replied to one of your diary entries.",
        "priority": "normal",
        "action": "open_diary_entry",
    },
]


def seed_notification_templates(db) -> None:
    for data in TEMPLATES:
        exists = (
            db.query(NotificationTemplate)
            .filter_by(type=data["type"])
            .first()
        )
        if exists:
            print(f"  skip  {data['type']} (already present)")
            continue

        template = NotificationTemplate(**data)
        db.add(template)
        db.commit()
        print(f"  added {data['type']}")


def main() -> None:
    db = SessionLocal()
    try:
        print("Seeding notification_templates …")
        seed_notification_templates(db)
        print("Done.")
    finally:
        db.close()


if __name__ == "__main__":
    main()
