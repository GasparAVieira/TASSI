import uuid
from datetime import datetime, timedelta, timezone
from unittest.mock import MagicMock

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.routers.admin_diary import list_diary_entries
from app.routers import admin_diary as admin_diary_module
from app.models.diary_entry import DiaryEntry
from app.models.diary_entry_comment import DiaryEntryComment  # registers mapper
from app.models.user import User
from app.models.notification_templates import NotificationTemplate  # registers mapper
from app.models.epoc_session import EpocSession  # registers mapper (required by User relationship)
from app.database import get_db
from app.dependencies import get_current_user
from app.core.enums import DiaryEntryType


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


def _seed_entry(db, participant_id, entry_type, recorded_at, body="body"):
    e = DiaryEntry(
        participant_id=participant_id,
        entry_type=entry_type,
        body=body,
        recorded_at=recorded_at,
    )
    db.add(e)
    db.flush()
    return e


def _seed_comment(db, entry_id, author_id, body="test comment"):
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
# TestClient setup (shared engine for 403 / 422 tests)
# ---------------------------------------------------------------------------

_val_engine = _build_engine(shared=True)
_admin_uid = uuid.uuid4()
_participant_uid = uuid.uuid4()
_seed_user(_val_engine, _admin_uid, role="admin")
_seed_user(_val_engine, _participant_uid, role="user")
_ValSession = sessionmaker(bind=_val_engine)


def _db_override():
    db = _ValSession()
    try:
        yield db
    finally:
        db.close()


# Admin client
_admin_app = FastAPI()
_admin_app.include_router(admin_diary_module.router)
_admin_app.dependency_overrides[get_db] = _db_override
_admin_app.dependency_overrides[get_current_user] = lambda: _make_user(_admin_uid, role="admin")
_admin_client = TestClient(_admin_app)

# Non-admin client (regular user → expect 403 on every admin endpoint)
_nonadmin_app = FastAPI()
_nonadmin_app.include_router(admin_diary_module.router)
_nonadmin_app.dependency_overrides[get_db] = _db_override
_nonadmin_app.dependency_overrides[get_current_user] = lambda: _make_user(_participant_uid, role="user")
_nonadmin_client = TestClient(_nonadmin_app)


# ---------------------------------------------------------------------------
# Integration tests — direct function calls with a real SQLite session
# ---------------------------------------------------------------------------

def test_admin_sees_entries_from_all_users():
    eng = _build_engine()
    uid_a = uuid.uuid4()
    uid_b = uuid.uuid4()
    _seed_user(eng, uid_a)
    _seed_user(eng, uid_b)
    db = sessionmaker(bind=eng)()

    base = datetime(2024, 1, 1, tzinfo=timezone.utc)
    for i in range(3):
        _seed_entry(db, uid_a, "text", base + timedelta(hours=i))
    for i in range(2):
        _seed_entry(db, uid_b, "text", base + timedelta(hours=10 + i))
    db.commit()

    result = list_diary_entries(db=db)

    assert result.total == 5
    participant_ids = {str(item.participant_id) for item in result.items}
    assert str(uid_a) in participant_ids
    assert str(uid_b) in participant_ids


def test_filter_by_participant_id():
    eng = _build_engine()
    uid_a = uuid.uuid4()
    uid_b = uuid.uuid4()
    _seed_user(eng, uid_a)
    _seed_user(eng, uid_b)
    db = sessionmaker(bind=eng)()

    base = datetime(2024, 1, 1, tzinfo=timezone.utc)
    for i in range(3):
        _seed_entry(db, uid_a, "text", base + timedelta(hours=i))
    for i in range(4):
        _seed_entry(db, uid_b, "text", base + timedelta(hours=10 + i))
    db.commit()

    result = list_diary_entries(db=db, participant_id=uid_a)

    assert result.total == 3
    assert all(str(item.participant_id) == str(uid_a) for item in result.items)


def test_filter_by_entry_type():
    eng = _build_engine()
    uid = uuid.uuid4()
    _seed_user(eng, uid)
    db = sessionmaker(bind=eng)()

    base = datetime(2024, 1, 1, tzinfo=timezone.utc)
    for i in range(4):
        _seed_entry(db, uid, "text", base + timedelta(hours=i))
    for i in range(2):
        _seed_entry(db, uid, "audio", base + timedelta(hours=10 + i))
    db.commit()

    result = list_diary_entries(db=db, entry_type=DiaryEntryType.text)

    assert result.total == 4
    assert all(item.entry_type == "text" for item in result.items)


def test_filter_has_comment_true():
    eng = _build_engine()
    uid = uuid.uuid4()
    admin_uid = uuid.uuid4()
    _seed_user(eng, uid)
    _seed_user(eng, admin_uid, role="admin")
    db = sessionmaker(bind=eng)()

    base = datetime(2024, 1, 1, tzinfo=timezone.utc)
    entry_with = _seed_entry(db, uid, "text", base)
    entry_without = _seed_entry(db, uid, "text", base + timedelta(hours=1))
    _seed_comment(db, entry_with.id, admin_uid)
    db.commit()

    result = list_diary_entries(db=db, has_comment=True)

    assert result.total == 1
    assert str(result.items[0].id) == str(entry_with.id)


def test_filter_has_comment_false():
    eng = _build_engine()
    uid = uuid.uuid4()
    admin_uid = uuid.uuid4()
    _seed_user(eng, uid)
    _seed_user(eng, admin_uid, role="admin")
    db = sessionmaker(bind=eng)()

    base = datetime(2024, 1, 1, tzinfo=timezone.utc)
    entry_with = _seed_entry(db, uid, "text", base)
    entry_without = _seed_entry(db, uid, "text", base + timedelta(hours=1))
    _seed_comment(db, entry_with.id, admin_uid)
    db.commit()

    result = list_diary_entries(db=db, has_comment=False)

    assert result.total == 1
    assert str(result.items[0].id) == str(entry_without.id)


def test_filter_has_comment_none_returns_all():
    eng = _build_engine()
    uid = uuid.uuid4()
    admin_uid = uuid.uuid4()
    _seed_user(eng, uid)
    _seed_user(eng, admin_uid, role="admin")
    db = sessionmaker(bind=eng)()

    base = datetime(2024, 1, 1, tzinfo=timezone.utc)
    entry_with = _seed_entry(db, uid, "text", base)
    entry_without = _seed_entry(db, uid, "text", base + timedelta(hours=1))
    _seed_comment(db, entry_with.id, admin_uid)
    db.commit()

    result = list_diary_entries(db=db, has_comment=None)

    assert result.total == 2


def test_filter_search_matches_body():
    eng = _build_engine()
    uid = uuid.uuid4()
    _seed_user(eng, uid)
    db = sessionmaker(bind=eng)()

    base = datetime(2024, 1, 1, tzinfo=timezone.utc)
    _seed_entry(db, uid, "text", base, body="difficulty navigating corridor")
    _seed_entry(db, uid, "text", base + timedelta(hours=1), body="enjoyed the tour")
    _seed_entry(db, uid, "text", base + timedelta(hours=2), body="Difficulty with stairs")
    db.commit()

    result = list_diary_entries(db=db, search="difficulty")

    assert result.total == 2


def test_filter_date_range():
    eng = _build_engine()
    uid = uuid.uuid4()
    _seed_user(eng, uid)
    db = sessionmaker(bind=eng)()

    base = datetime(2024, 1, 1, tzinfo=timezone.utc)
    for i in range(7):
        _seed_entry(db, uid, "text", base + timedelta(days=i))
    db.commit()

    recorded_from = base + timedelta(days=2)
    recorded_to = base + timedelta(days=4)
    result = list_diary_entries(db=db, recorded_from=recorded_from, recorded_to=recorded_to)

    assert result.total == 3  # days 2, 3, 4


def test_filters_combined_participant_type_date():
    eng = _build_engine()
    uid_a = uuid.uuid4()
    uid_b = uuid.uuid4()
    _seed_user(eng, uid_a)
    _seed_user(eng, uid_b)
    db = sessionmaker(bind=eng)()

    base = datetime(2024, 1, 1, tzinfo=timezone.utc)
    for i in range(6):
        _seed_entry(db, uid_a, "text", base + timedelta(days=i))
    for i in range(3):
        _seed_entry(db, uid_a, "audio", base + timedelta(days=i))
    for i in range(4):
        _seed_entry(db, uid_b, "text", base + timedelta(days=i))
    db.commit()

    result = list_diary_entries(
        db=db,
        participant_id=uid_a,
        entry_type=DiaryEntryType.text,
        recorded_from=base + timedelta(days=2),
        recorded_to=base + timedelta(days=4),
    )

    # uid_a text entries on days 2–4 = 3
    assert result.total == 3
    assert all(item.entry_type == "text" for item in result.items)
    assert all(str(item.participant_id) == str(uid_a) for item in result.items)


def test_pagination_limit():
    eng = _build_engine()
    uid = uuid.uuid4()
    _seed_user(eng, uid)
    db = sessionmaker(bind=eng)()

    base = datetime(2024, 1, 1, tzinfo=timezone.utc)
    for i in range(10):
        _seed_entry(db, uid, "text", base + timedelta(hours=i))
    db.commit()

    result = list_diary_entries(db=db, limit=3)

    assert result.total == 10
    assert len(result.items) == 3
    assert result.limit == 3


def test_pagination_offset():
    eng = _build_engine()
    uid = uuid.uuid4()
    _seed_user(eng, uid)
    db = sessionmaker(bind=eng)()

    base = datetime(2024, 1, 1, tzinfo=timezone.utc)
    for i in range(5):
        _seed_entry(db, uid, "text", base + timedelta(hours=i))
    db.commit()

    result = list_diary_entries(db=db, offset=3)

    assert result.total == 5
    assert len(result.items) == 2
    assert result.offset == 3


def test_pagination_returns_most_recent_first():
    eng = _build_engine()
    uid = uuid.uuid4()
    _seed_user(eng, uid)
    db = sessionmaker(bind=eng)()

    base = datetime(2024, 1, 1, tzinfo=timezone.utc)
    for i in range(5):
        _seed_entry(db, uid, "text", base + timedelta(days=i))
    db.commit()

    result = list_diary_entries(db=db)

    recorded_ats = [item.recorded_at for item in result.items]
    assert recorded_ats == sorted(recorded_ats, reverse=True)


# ---------------------------------------------------------------------------
# HTTP tests via TestClient
# ---------------------------------------------------------------------------

def test_non_admin_gets_403_on_list():
    resp = _nonadmin_client.get("/api/v1/admin/diary-entries/")
    assert resp.status_code == 403


def test_non_admin_gets_403_on_get_single():
    resp = _nonadmin_client.get(f"/api/v1/admin/diary-entries/{uuid.uuid4()}")
    assert resp.status_code == 403


def test_admin_list_returns_200():
    resp = _admin_client.get("/api/v1/admin/diary-entries/")
    assert resp.status_code == 200
    body = resp.json()
    assert "items" in body
    assert "total" in body


def test_422_limit_too_high():
    resp = _admin_client.get("/api/v1/admin/diary-entries/?limit=101")
    assert resp.status_code == 422


def test_422_limit_zero():
    resp = _admin_client.get("/api/v1/admin/diary-entries/?limit=0")
    assert resp.status_code == 422


def test_422_negative_offset():
    resp = _admin_client.get("/api/v1/admin/diary-entries/?offset=-1")
    assert resp.status_code == 422


def test_422_invalid_entry_type():
    resp = _admin_client.get("/api/v1/admin/diary-entries/?entry_type=bogus")
    assert resp.status_code == 422
