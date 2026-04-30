import uuid
from datetime import datetime, timezone
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from fastapi import FastAPI, HTTPException
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.routers.admin_diary import create_entry_comment, update_entry_comment, delete_entry_comment
from app.routers import admin_diary as admin_diary_module
from app.routers.diary_entries import get_diary_entry as participant_get_diary_entry
from app.models.diary_entry import DiaryEntry
from app.models.diary_entry_comment import DiaryEntryComment  # registers mapper
from app.models.user import User
from app.models.notification_templates import NotificationTemplate  # registers mapper
from app.models.epoc_session import EpocSession  # registers mapper (required by User relationship)
from app.database import get_db
from app.dependencies import get_current_user
from app.schemas.diary_entry_comment import DiaryEntryCommentCreate, DiaryEntryCommentUpdate


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
        conn.commit()
    return eng


def _seed_user(eng, uid, role="user"):
    with eng.connect() as conn:
        conn.execute(
            text("INSERT INTO users VALUES (:id,'Test User',:email,'hash',NULL,NULL,:role,'none','pt',0,CURRENT_TIMESTAMP,CURRENT_TIMESTAMP)"),
            {"id": str(uid), "email": f"{uid}@test.com", "role": role},
        )
        conn.commit()


def _seed_entry(db, participant_id, entry_type="text", body="body"):
    e = DiaryEntry(
        participant_id=participant_id,
        entry_type=entry_type,
        body=body,
        recorded_at=datetime(2024, 6, 1, tzinfo=timezone.utc),
    )
    db.add(e)
    db.flush()
    return e


def _seed_comment(db, entry_id, author_id, body="admin comment"):
    c = DiaryEntryComment(entry_id=entry_id, author_id=author_id, body=body)
    db.add(c)
    db.flush()
    return c


def _make_user(uid, role="admin"):
    u = MagicMock(spec=User)
    u.id = uid
    u.role = role
    return u


# ---------------------------------------------------------------------------
# TestClient setup (shared engine for HTTP tests)
# ---------------------------------------------------------------------------

_shared_engine = _build_engine(shared=True)
_participant_uid = uuid.uuid4()
_admin_uid = uuid.uuid4()
_other_admin_uid = uuid.uuid4()
_seed_user(_shared_engine, _participant_uid, role="user")
_seed_user(_shared_engine, _admin_uid, role="admin")
_seed_user(_shared_engine, _other_admin_uid, role="admin")
_SharedSession = sessionmaker(bind=_shared_engine)

# Seed an entry for the shared engine
_shared_db = _SharedSession()
_shared_entry = _seed_entry(_shared_db, _participant_uid)
_shared_db.commit()
_shared_entry_id = _shared_entry.id
_shared_db.close()


def _db_override():
    db = _SharedSession()
    try:
        yield db
    finally:
        db.close()


def _admin_override():
    return _make_user(_admin_uid, role="admin")


def _nonadmin_override():
    return _make_user(_participant_uid, role="user")


_admin_app = FastAPI()
_admin_app.include_router(admin_diary_module.router)
_admin_app.dependency_overrides[get_db] = _db_override
_admin_app.dependency_overrides[get_current_user] = _admin_override
_admin_client = TestClient(_admin_app)

_nonadmin_app = FastAPI()
_nonadmin_app.include_router(admin_diary_module.router)
_nonadmin_app.dependency_overrides[get_db] = _db_override
_nonadmin_app.dependency_overrides[get_current_user] = _nonadmin_override
_nonadmin_client = TestClient(_nonadmin_app)


# ---------------------------------------------------------------------------
# POST comment tests (via TestClient — route is async)
# ---------------------------------------------------------------------------

def test_admin_can_post_comment():
    with patch("app.routers.admin_diary.create_user_notification", return_value=None):
        resp = _admin_client.post(
            f"/api/v1/admin/diary-entries/{_shared_entry_id}/comments",
            json={"body": "Great progress noted."},
        )
    assert resp.status_code == 201
    body = resp.json()
    assert body["body"] == "Great progress noted."
    assert body["author_id"] == str(_admin_uid)


def test_non_admin_gets_403_on_post_comment():
    resp = _nonadmin_client.post(
        f"/api/v1/admin/diary-entries/{_shared_entry_id}/comments",
        json={"body": "Sneaky comment."},
    )
    assert resp.status_code == 403


def test_post_comment_on_missing_entry_returns_404():
    with patch("app.routers.admin_diary.create_user_notification", return_value=None):
        resp = _admin_client.post(
            f"/api/v1/admin/diary-entries/{uuid.uuid4()}/comments",
            json={"body": "Ghost entry."},
        )
    assert resp.status_code == 404


# ---------------------------------------------------------------------------
# Comment visible in participant GET /diary-entries/{id}
# ---------------------------------------------------------------------------

def test_comment_visible_in_participant_view():
    eng = _build_engine()
    participant_uid = uuid.uuid4()
    admin_uid = uuid.uuid4()
    _seed_user(eng, participant_uid)
    _seed_user(eng, admin_uid, role="admin")
    db = sessionmaker(bind=eng)()

    entry = _seed_entry(db, participant_uid)
    comment = _seed_comment(db, entry.id, admin_uid, body="Admin feedback here.")
    db.commit()

    result = participant_get_diary_entry(
        entry_id=entry.id,
        db=db,
        current_user=_make_user(participant_uid, role="user"),
    )

    assert len(result.comments) == 1
    assert result.comments[0].body == "Admin feedback here."


# ---------------------------------------------------------------------------
# PATCH (update) authorization tests — direct function calls
# ---------------------------------------------------------------------------

def test_admin_can_update_own_comment():
    eng = _build_engine()
    participant_uid = uuid.uuid4()
    admin_uid = uuid.uuid4()
    _seed_user(eng, participant_uid)
    _seed_user(eng, admin_uid, role="admin")
    db = sessionmaker(bind=eng)()

    entry = _seed_entry(db, participant_uid)
    comment = _seed_comment(db, entry.id, admin_uid, body="original")
    db.commit()

    result = update_entry_comment(
        comment_id=comment.id,
        payload=DiaryEntryCommentUpdate(body="updated"),
        db=db,
        current_user=_make_user(admin_uid, role="admin"),
    )

    assert result.body == "updated"


def test_superadmin_can_update_any_comment():
    eng = _build_engine()
    participant_uid = uuid.uuid4()
    admin_uid = uuid.uuid4()
    superadmin_uid = uuid.uuid4()
    _seed_user(eng, participant_uid)
    _seed_user(eng, admin_uid, role="admin")
    _seed_user(eng, superadmin_uid, role="superadmin")
    db = sessionmaker(bind=eng)()

    entry = _seed_entry(db, participant_uid)
    comment = _seed_comment(db, entry.id, admin_uid, body="admin wrote this")
    db.commit()

    result = update_entry_comment(
        comment_id=comment.id,
        payload=DiaryEntryCommentUpdate(body="superadmin override"),
        db=db,
        current_user=_make_user(superadmin_uid, role="superadmin"),
    )

    assert result.body == "superadmin override"


def test_admin_cannot_update_other_admins_comment():
    eng = _build_engine()
    participant_uid = uuid.uuid4()
    admin_a = uuid.uuid4()
    admin_b = uuid.uuid4()
    _seed_user(eng, participant_uid)
    _seed_user(eng, admin_a, role="admin")
    _seed_user(eng, admin_b, role="admin")
    db = sessionmaker(bind=eng)()

    entry = _seed_entry(db, participant_uid)
    comment = _seed_comment(db, entry.id, admin_a, body="admin A wrote this")
    db.commit()

    with pytest.raises(HTTPException) as exc:
        update_entry_comment(
            comment_id=comment.id,
            payload=DiaryEntryCommentUpdate(body="admin B trying to edit"),
            db=db,
            current_user=_make_user(admin_b, role="admin"),
        )
    assert exc.value.status_code == 403


# ---------------------------------------------------------------------------
# DELETE authorization tests — direct function calls
# ---------------------------------------------------------------------------

def test_admin_can_delete_own_comment():
    eng = _build_engine()
    participant_uid = uuid.uuid4()
    admin_uid = uuid.uuid4()
    _seed_user(eng, participant_uid)
    _seed_user(eng, admin_uid, role="admin")
    db = sessionmaker(bind=eng)()

    entry = _seed_entry(db, participant_uid)
    comment = _seed_comment(db, entry.id, admin_uid)
    comment_id = comment.id
    db.commit()

    delete_entry_comment(
        comment_id=comment_id,
        db=db,
        current_user=_make_user(admin_uid, role="admin"),
    )

    remaining = db.query(DiaryEntryComment).filter(DiaryEntryComment.id == comment_id).first()
    assert remaining is None


def test_superadmin_can_delete_any_comment():
    eng = _build_engine()
    participant_uid = uuid.uuid4()
    admin_uid = uuid.uuid4()
    superadmin_uid = uuid.uuid4()
    _seed_user(eng, participant_uid)
    _seed_user(eng, admin_uid, role="admin")
    _seed_user(eng, superadmin_uid, role="superadmin")
    db = sessionmaker(bind=eng)()

    entry = _seed_entry(db, participant_uid)
    comment = _seed_comment(db, entry.id, admin_uid)
    comment_id = comment.id
    db.commit()

    delete_entry_comment(
        comment_id=comment_id,
        db=db,
        current_user=_make_user(superadmin_uid, role="superadmin"),
    )

    remaining = db.query(DiaryEntryComment).filter(DiaryEntryComment.id == comment_id).first()
    assert remaining is None


def test_admin_cannot_delete_other_admins_comment():
    eng = _build_engine()
    participant_uid = uuid.uuid4()
    admin_a = uuid.uuid4()
    admin_b = uuid.uuid4()
    _seed_user(eng, participant_uid)
    _seed_user(eng, admin_a, role="admin")
    _seed_user(eng, admin_b, role="admin")
    db = sessionmaker(bind=eng)()

    entry = _seed_entry(db, participant_uid)
    comment = _seed_comment(db, entry.id, admin_a, body="admin A's comment")
    db.commit()

    with pytest.raises(HTTPException) as exc:
        delete_entry_comment(
            comment_id=comment.id,
            db=db,
            current_user=_make_user(admin_b, role="admin"),
        )
    assert exc.value.status_code == 403
