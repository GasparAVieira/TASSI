import uuid
from datetime import datetime, timezone
from unittest.mock import MagicMock

import pytest
from fastapi import HTTPException
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

from app.routers.diary_entries import update_diary_entry
from app.schemas.diary_entry import DiaryEntryUpdate
from app.schemas.diary_media import DiaryMediaCreate
from app.models.diary_entry import DiaryEntry
from app.models.diary_media import DiaryMedia
from app.models.user import User
from app.models.notification_templates import NotificationTemplate  # registers mapper
from app.models.diary_entry_comment import DiaryEntryComment  # registers mapper
from app.models.epoc_session import EpocSession  # registers mapper (required by User relationship)

_NOW = datetime.now(timezone.utc)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _user(uid=None):
    u = MagicMock(spec=User)
    u.id = uid or uuid.uuid4()
    return u


def _mock_db(found):
    """Mock Session whose query().options().filter().first() returns `found`."""
    db = MagicMock()
    db.query.return_value.options.return_value.filter.return_value.first.return_value = found
    return db


def _cascade_engine():
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


def _seed_user(eng, uid):
    with eng.connect() as conn:
        conn.execute(
            text("INSERT INTO users VALUES (:id,'T','t@t.com','h',NULL,NULL,'user','none','pt',0,CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)"),
            {"id": str(uid)},
        )
        conn.commit()


# ---------------------------------------------------------------------------
# Mock-based tests — 404 paths (no DB state needed)
# ---------------------------------------------------------------------------

def test_update_nonexistent_entry_raises_404():
    user = _user()
    db = _mock_db(None)

    with pytest.raises(HTTPException) as exc:
        update_diary_entry(uuid.uuid4(), DiaryEntryUpdate(), db, user)

    assert exc.value.status_code == 404
    db.commit.assert_not_called()


def test_update_other_users_entry_raises_404():
    attacker = _user()
    db = _mock_db(None)  # ownership filter finds nothing for the attacker

    with pytest.raises(HTTPException) as exc:
        update_diary_entry(uuid.uuid4(), DiaryEntryUpdate(), db, attacker)

    assert exc.value.status_code == 404
    db.commit.assert_not_called()


# ---------------------------------------------------------------------------
# Real SQLite integration tests
# ---------------------------------------------------------------------------

def test_scalar_only_update_leaves_media_untouched():
    """Updating only scalar fields must not remove existing media items."""
    eng = _cascade_engine()
    uid = uuid.uuid4()
    _seed_user(eng, uid)
    db = sessionmaker(bind=eng)()

    entry = DiaryEntry(participant_id=uid, entry_type="audio", recorded_at=_NOW)
    db.add(entry)
    db.flush()
    db.add(DiaryMedia(entry_id=entry.id, media_type="audio", url="http://x/a.mp3"))
    db.commit()
    entry_id = entry.id

    payload = DiaryEntryUpdate(duration_sec=30.0)  # media_items omitted
    result = update_diary_entry(entry_id, payload, db, _user(uid))

    assert result.duration_sec == 30.0
    assert len(result.media_items) == 1
    assert result.media_items[0].url == "http://x/a.mp3"
    db.close()


def test_media_only_update_replaces_all_media():
    """When media_items is provided, existing media is fully replaced."""
    eng = _cascade_engine()
    uid = uuid.uuid4()
    _seed_user(eng, uid)
    db = sessionmaker(bind=eng)()

    entry = DiaryEntry(participant_id=uid, entry_type="video", recorded_at=_NOW)
    db.add(entry)
    db.flush()
    db.add(DiaryMedia(entry_id=entry.id, media_type="video", url="http://x/old.mp4"))
    db.commit()
    entry_id = entry.id

    new_url = "http://x/new.mp4"
    payload = DiaryEntryUpdate(
        media_items=[DiaryMediaCreate(media_type="video", url=new_url)]
    )
    result = update_diary_entry(entry_id, payload, db, _user(uid))

    assert [m.url for m in result.media_items] == [new_url]
    assert db.query(DiaryMedia).filter_by(url="http://x/old.mp4").first() is None
    db.close()


def test_mixed_update_applies_scalar_and_media_changes():
    """Scalar fields and media replacement both apply in the same request."""
    eng = _cascade_engine()
    uid = uuid.uuid4()
    _seed_user(eng, uid)
    db = sessionmaker(bind=eng)()

    entry = DiaryEntry(participant_id=uid, entry_type="video", recorded_at=_NOW)
    db.add(entry)
    db.flush()
    db.add(DiaryMedia(entry_id=entry.id, media_type="video", url="http://x/old.mp4"))
    db.commit()
    entry_id = entry.id

    payload = DiaryEntryUpdate(
        duration_sec=42.0,
        media_items=[DiaryMediaCreate(media_type="video", url="http://x/new.mp4")],
    )
    result = update_diary_entry(entry_id, payload, db, _user(uid))

    assert result.duration_sec == 42.0
    assert len(result.media_items) == 1
    assert result.media_items[0].url == "http://x/new.mp4"
    db.close()


def test_media_update_leaving_video_with_no_media_raises_400():
    """Replacing a video entry's media with an empty list must be rejected."""
    eng = _cascade_engine()
    uid = uuid.uuid4()
    _seed_user(eng, uid)
    db = sessionmaker(bind=eng)()

    entry = DiaryEntry(participant_id=uid, entry_type="video", recorded_at=_NOW)
    db.add(entry)
    db.flush()
    db.add(DiaryMedia(entry_id=entry.id, media_type="video", url="http://x/v.mp4"))
    db.commit()
    entry_id = entry.id

    payload = DiaryEntryUpdate(media_items=[])  # would strip all media from a video entry
    with pytest.raises(HTTPException) as exc:
        update_diary_entry(entry_id, payload, db, _user(uid))

    assert exc.value.status_code == 400
    db.close()
