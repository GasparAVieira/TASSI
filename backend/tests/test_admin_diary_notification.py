"""
Tests that posting an admin comment triggers the notification pipeline:
  - a UserNotification row is created with template type diary_admin_response
  - notification_manager.send_to_user is called with the participant's id
  - when no active template exists nothing is inserted and send_to_user is not called
"""
import uuid
from datetime import datetime, timezone
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.routers import admin_diary as admin_diary_module
from app.models.diary_entry import DiaryEntry
from app.models.diary_entry_comment import DiaryEntryComment  # registers mapper
from app.models.user import User
from app.models.notification_templates import NotificationTemplate  # registers mapper
from app.models.user_notifications import UserNotification  # registers mapper
from app.models.epoc_session import EpocSession  # registers mapper (required by User relationship)
from app.database import get_db
from app.dependencies import get_current_user
from app.core.notification_manager import notification_manager


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _build_engine(shared: bool = False):
    kwargs: dict = {"connect_args": {"check_same_thread": False}}
    if shared:
        kwargs["poolclass"] = StaticPool
    eng = create_engine("sqlite://", **kwargs)
    with eng.connect() as conn:
        conn.execute(text("""
            CREATE TABLE users (
                id TEXT PRIMARY KEY,
                full_name TEXT NOT NULL,
                email TEXT NOT NULL,
                password_hash TEXT NOT NULL,
                phone TEXT,
                bio TEXT,
                role TEXT NOT NULL,
                accessibility_profile TEXT NOT NULL,
                preferred_language TEXT NOT NULL,
                audio_guidance INTEGER NOT NULL,
                created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
            )
        """))
        conn.execute(text("""
            CREATE TABLE diary_entries (
                id TEXT PRIMARY KEY,
                participant_id TEXT NOT NULL,
                entry_type TEXT NOT NULL,
                body TEXT,
                duration_sec REAL,
                recorded_at TEXT NOT NULL,
                location_id TEXT,
                building_id TEXT,
                context_notes TEXT,
                is_synced INTEGER NOT NULL DEFAULT 1,
                created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
            )
        """))
        conn.execute(text("""
            CREATE TABLE diary_media (
                id TEXT PRIMARY KEY,
                entry_id TEXT NOT NULL,
                media_type TEXT NOT NULL,
                url TEXT NOT NULL,
                duration_sec REAL,
                transcription TEXT,
                language TEXT,
                created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
            )
        """))
        conn.execute(text("""
            CREATE TABLE diary_entry_comments (
                id TEXT PRIMARY KEY,
                entry_id TEXT NOT NULL,
                author_id TEXT,
                body TEXT NOT NULL,
                created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
            )
        """))
        conn.execute(text("""
            CREATE TABLE notification_templates (
                id TEXT PRIMARY KEY,
                type TEXT NOT NULL,
                title_pt TEXT NOT NULL,
                message_pt TEXT NOT NULL,
                title_en TEXT,
                message_en TEXT,
                priority TEXT NOT NULL DEFAULT 'normal',
                action TEXT,
                is_active INTEGER NOT NULL DEFAULT 1
            )
        """))
        conn.execute(text("""
            CREATE TABLE user_notifications (
                id TEXT PRIMARY KEY,
                user_id TEXT NOT NULL,
                template_id TEXT NOT NULL,
                shown_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
                read_at TEXT,
                dismissed_at TEXT,
                expires_at TEXT
            )
        """))
        conn.commit()
    return eng


def _seed_template(eng):
    # Use ORM so the UUID storage format matches what relationship lazy-loads expect.
    Session = sessionmaker(bind=eng)
    db = Session()
    tmpl = NotificationTemplate(
        type="diary_admin_response",
        title_pt="Resposta do admin",
        message_pt="O admin respondeu.",
        is_active=True,
    )
    db.add(tmpl)
    db.commit()
    db.close()


def _seed_user(eng, uid, role="user"):
    # Use ORM so UUID storage format matches what the route's ORM queries expect.
    Session = sessionmaker(bind=eng)
    db = Session()
    user = User(
        id=uid,
        full_name="Test User",
        email=f"{uid}@test.com",
        password_hash="hash",
        role=role,
    )
    db.add(user)
    db.commit()
    db.close()


def _seed_entry(eng, participant_id):
    # Use ORM so UUID storage format is consistent with route queries.
    Session = sessionmaker(bind=eng)
    db = Session()
    entry = DiaryEntry(
        participant_id=participant_id,
        entry_type="text",
        body="entry body",
        recorded_at=datetime(2024, 6, 1, tzinfo=timezone.utc),
    )
    db.add(entry)
    db.commit()
    entry_id = entry.id
    db.close()
    return entry_id


def _make_user(uid, role="admin"):
    u = MagicMock(spec=User)
    u.id = uid
    u.role = role
    return u


def _make_client(eng, admin_uid):
    Session = sessionmaker(bind=eng)

    def _db_override():
        db = Session()
        try:
            yield db
        finally:
            db.close()

    def _user_override():
        return _make_user(admin_uid, role="admin")

    app = FastAPI()
    app.include_router(admin_diary_module.router)
    app.dependency_overrides[get_db] = _db_override
    app.dependency_overrides[get_current_user] = _user_override
    return TestClient(app), Session


# ---------------------------------------------------------------------------
# Tests: notification row is created
# ---------------------------------------------------------------------------

def test_posting_comment_creates_user_notification_row():
    participant_uid = uuid.uuid4()
    admin_uid = uuid.uuid4()

    eng = _build_engine(shared=True)
    _seed_user(eng, participant_uid, role="user")
    _seed_user(eng, admin_uid, role="admin")
    entry_id = _seed_entry(eng, participant_uid)
    _seed_template(eng)

    client, Session = _make_client(eng, admin_uid)

    with patch.object(notification_manager, "send_to_user", new_callable=AsyncMock):
        resp = client.post(
            f"/api/v1/admin/diary-entries/{entry_id}/comments",
            json={"body": "Keep it up!"},
        )

    assert resp.status_code == 201

    db = Session()
    notification = (
        db.query(UserNotification)
        .filter(UserNotification.user_id == participant_uid)
        .first()
    )
    db.close()

    assert notification is not None


def test_posting_comment_uses_diary_admin_response_template():
    participant_uid = uuid.uuid4()
    admin_uid = uuid.uuid4()

    eng = _build_engine(shared=True)
    _seed_user(eng, participant_uid, role="user")
    _seed_user(eng, admin_uid, role="admin")
    entry_id = _seed_entry(eng, participant_uid)
    _seed_template(eng)

    client, Session = _make_client(eng, admin_uid)

    with patch.object(notification_manager, "send_to_user", new_callable=AsyncMock):
        client.post(
            f"/api/v1/admin/diary-entries/{entry_id}/comments",
            json={"body": "Well done."},
        )

    db = Session()
    notification = (
        db.query(UserNotification)
        .join(NotificationTemplate)
        .filter(
            UserNotification.user_id == participant_uid,
            NotificationTemplate.type == "diary_admin_response",
        )
        .first()
    )
    db.close()

    assert notification is not None


def test_posting_comment_calls_send_to_user():
    participant_uid = uuid.uuid4()
    admin_uid = uuid.uuid4()

    eng = _build_engine(shared=True)
    _seed_user(eng, participant_uid, role="user")
    _seed_user(eng, admin_uid, role="admin")
    entry_id = _seed_entry(eng, participant_uid)
    _seed_template(eng)

    client, _ = _make_client(eng, admin_uid)

    with patch.object(notification_manager, "send_to_user", new_callable=AsyncMock) as mock_send:
        resp = client.post(
            f"/api/v1/admin/diary-entries/{entry_id}/comments",
            json={"body": "Noted."},
        )

    assert resp.status_code == 201
    mock_send.assert_called_once()
    call_args = mock_send.call_args
    # first positional arg is the participant's user id
    assert call_args.args[0] == participant_uid


def test_send_to_user_payload_contains_notification_event():
    participant_uid = uuid.uuid4()
    admin_uid = uuid.uuid4()

    eng = _build_engine(shared=True)
    _seed_user(eng, participant_uid, role="user")
    _seed_user(eng, admin_uid, role="admin")
    entry_id = _seed_entry(eng, participant_uid)
    _seed_template(eng)

    client, _ = _make_client(eng, admin_uid)

    with patch.object(notification_manager, "send_to_user", new_callable=AsyncMock) as mock_send:
        client.post(
            f"/api/v1/admin/diary-entries/{entry_id}/comments",
            json={"body": "Noted."},
        )

    payload = mock_send.call_args.args[1]
    assert payload["event"] == "notification.created"
    assert "data" in payload


# ---------------------------------------------------------------------------
# Tests: no notification when template is missing
# ---------------------------------------------------------------------------

def test_no_notification_row_when_template_missing():
    participant_uid = uuid.uuid4()
    admin_uid = uuid.uuid4()

    eng = _build_engine(shared=True)  # intentionally no template
    _seed_user(eng, participant_uid, role="user")
    _seed_user(eng, admin_uid, role="admin")
    entry_id = _seed_entry(eng, participant_uid)

    client, Session = _make_client(eng, admin_uid)

    resp = client.post(
        f"/api/v1/admin/diary-entries/{entry_id}/comments",
        json={"body": "No template in DB."},
    )

    assert resp.status_code == 201

    db = Session()
    count = db.query(UserNotification).count()
    db.close()

    assert count == 0


def test_send_to_user_not_called_when_template_missing():
    participant_uid = uuid.uuid4()
    admin_uid = uuid.uuid4()

    eng = _build_engine(shared=True)  # intentionally no template
    _seed_user(eng, participant_uid, role="user")
    _seed_user(eng, admin_uid, role="admin")
    entry_id = _seed_entry(eng, participant_uid)

    client, _ = _make_client(eng, admin_uid)

    with patch.object(notification_manager, "send_to_user", new_callable=AsyncMock) as mock_send:
        client.post(
            f"/api/v1/admin/diary-entries/{entry_id}/comments",
            json={"body": "No notification please."},
        )

    mock_send.assert_not_called()
