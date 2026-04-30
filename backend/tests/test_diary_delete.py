import uuid
from datetime import datetime, timezone
from unittest.mock import MagicMock, call

import pytest
from fastapi import HTTPException
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

from app.routers.diary_entries import delete_diary_entry
from app.models.diary_entry import DiaryEntry
from app.models.diary_media import DiaryMedia
from app.models.user import User
from app.models.notification_templates import NotificationTemplate  # registers mapper
from app.models.diary_entry_comment import DiaryEntryComment  # registers mapper
from app.models.epoc_session import EpocSession  # registers mapper (required by User relationship)


# ---------------------------------------------------------------------------
# Helpers for mock-based unit tests (tests 1–3)
# ---------------------------------------------------------------------------

def _mock_db(found):
    """Return a mock Session whose query().filter().first() returns `found`."""
    db = MagicMock()
    db.query.return_value.filter.return_value.first.return_value = found
    return db


def _user():
    u = MagicMock(spec=User)
    u.id = uuid.uuid4()
    return u


def _entry(owner_id):
    e = MagicMock(spec=DiaryEntry)
    e.id = uuid.uuid4()
    e.participant_id = owner_id
    return e


# ---------------------------------------------------------------------------
# Helpers for the real-SQLite cascade test (test 4)
# ---------------------------------------------------------------------------

def _cascade_engine():
    """In-memory SQLite engine with tables created via raw SQL (avoids JSONB)."""
    eng = create_engine("sqlite://", connect_args={"check_same_thread": False})
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
            CREATE TABLE notification_templates (
                id TEXT PRIMARY KEY,
                type TEXT NOT NULL,
                title_pt TEXT NOT NULL,
                message_pt TEXT NOT NULL,
                priority TEXT NOT NULL,
                is_active INTEGER NOT NULL
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
        conn.commit()
    return eng


# ---------------------------------------------------------------------------
# Test 1 — successful delete returns None (204 No Content) and persists changes
# ---------------------------------------------------------------------------

def test_delete_success():
    user = _user()
    entry = _entry(user.id)
    db = _mock_db(entry)

    result = delete_diary_entry(entry.id, db, user)

    assert result is None
    db.delete.assert_called_once_with(entry)
    db.commit.assert_called_once()


# ---------------------------------------------------------------------------
# Test 2 — non-existent id raises 404 without touching the DB
# ---------------------------------------------------------------------------

def test_delete_nonexistent():
    user = _user()
    db = _mock_db(None)

    with pytest.raises(HTTPException) as exc:
        delete_diary_entry(uuid.uuid4(), db, user)

    assert exc.value.status_code == 404
    db.delete.assert_not_called()
    db.commit.assert_not_called()


# ---------------------------------------------------------------------------
# Test 3 — another user's entry returns 404 (ownership filter returns None)
# ---------------------------------------------------------------------------

def test_delete_other_users_entry():
    attacker = _user()
    db = _mock_db(None)  # ownership filter finds nothing for the attacker

    with pytest.raises(HTTPException) as exc:
        delete_diary_entry(uuid.uuid4(), db, attacker)

    assert exc.value.status_code == 404
    db.delete.assert_not_called()
    db.commit.assert_not_called()


# ---------------------------------------------------------------------------
# Test 4 — media rows are gone after a successful delete (real SQLite session)
# ---------------------------------------------------------------------------

def test_delete_cascade_removes_media():
    eng = _cascade_engine()
    Sess = sessionmaker(bind=eng)
    db = Sess()

    # Seed a user row via raw SQL so User model constraints are not an issue
    uid = uuid.uuid4()
    with eng.connect() as conn:
        conn.execute(
            text("INSERT INTO users VALUES (:id,'T','t@t.com','h',NULL,NULL,'user','none','pt',0,CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)"),
            {"id": str(uid)},
        )
        conn.commit()

    # Create entry + two media items via ORM
    now = datetime.now(timezone.utc)
    entry = DiaryEntry(participant_id=uid, entry_type="text", body="b", recorded_at=now)
    db.add(entry)
    db.flush()

    m1 = DiaryMedia(entry_id=entry.id, media_type="audio", url="http://x/1.mp3")
    m2 = DiaryMedia(entry_id=entry.id, media_type="audio", url="http://x/2.mp3")
    db.add_all([m1, m2])
    db.commit()

    entry_id, m1_id, m2_id = entry.id, m1.id, m2.id

    # Call the actual handler with this real session
    user_mock = MagicMock(spec=User)
    user_mock.id = uid
    delete_diary_entry(entry_id, db, user_mock)

    # Verify both the entry and its media are gone
    assert db.query(DiaryEntry).filter(DiaryEntry.id == entry_id).first() is None
    assert db.query(DiaryMedia).filter(DiaryMedia.id == m1_id).first() is None
    assert db.query(DiaryMedia).filter(DiaryMedia.id == m2_id).first() is None

    db.close()
