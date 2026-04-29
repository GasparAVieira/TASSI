import uuid
from datetime import datetime, timedelta, timezone
from unittest.mock import MagicMock

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.routers.diary_entries import list_my_diary_entries
from app.routers import diary_entries as diary_entries_module
from app.models.diary_entry import DiaryEntry
from app.models.user import User
from app.models.notification_templates import NotificationTemplate  # registers mapper
from app.database import get_db
from app.dependencies import get_current_user
from app.core.enums import DiaryEntryType


# ---------------------------------------------------------------------------
# SQLite helpers
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
                role TEXT NOT NULL,
                accessibility_profile TEXT NOT NULL,
                preferred_language TEXT NOT NULL,
                audio_guidance INTEGER NOT NULL
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
        conn.commit()
    return eng


def _seed_user(eng, uid):
    with eng.connect() as conn:
        conn.execute(
            text("INSERT INTO users VALUES (:id,'T','t@t.com','h','user','none','pt',0)"),
            {"id": str(uid)},
        )
        conn.commit()


def _seed_entry(db, uid, entry_type, recorded_at, body="body"):
    e = DiaryEntry(
        participant_id=uid,
        entry_type=entry_type,
        body=body,
        recorded_at=recorded_at,
    )
    db.add(e)
    db.flush()
    return e


def _make_user(uid):
    u = MagicMock(spec=User)
    u.id = uid
    return u


# ---------------------------------------------------------------------------
# TestClient for 422 validation tests
# ---------------------------------------------------------------------------

_val_engine = _build_engine(shared=True)
_val_uid = uuid.uuid4()
_seed_user(_val_engine, _val_uid)
_ValSession = sessionmaker(bind=_val_engine)


def _override_db():
    db = _ValSession()
    try:
        yield db
    finally:
        db.close()


def _override_user():
    return _make_user(_val_uid)


_test_app = FastAPI()
_test_app.include_router(diary_entries_module.router)
_test_app.dependency_overrides[get_db] = _override_db
_test_app.dependency_overrides[get_current_user] = _override_user
_client = TestClient(_test_app)


# ---------------------------------------------------------------------------
# Business logic tests (direct function calls with real SQLite session)
# ---------------------------------------------------------------------------

def test_empty_result():
    eng = _build_engine()
    uid = uuid.uuid4()
    _seed_user(eng, uid)
    db = sessionmaker(bind=eng)()

    result = list_my_diary_entries(db=db, current_user=_make_user(uid))

    assert result.items == []
    assert result.total == 0
    assert result.limit == 20
    assert result.offset == 0


def test_pagination_default_limit():
    eng = _build_engine()
    uid = uuid.uuid4()
    _seed_user(eng, uid)
    db = sessionmaker(bind=eng)()

    base = datetime(2024, 1, 1, tzinfo=timezone.utc)
    for i in range(25):
        _seed_entry(db, uid, "text", base + timedelta(hours=i))
    db.commit()

    result = list_my_diary_entries(db=db, current_user=_make_user(uid))

    assert result.total == 25
    assert len(result.items) == 20
    assert result.limit == 20
    assert result.offset == 0


def test_pagination_custom_limit():
    eng = _build_engine()
    uid = uuid.uuid4()
    _seed_user(eng, uid)
    db = sessionmaker(bind=eng)()

    base = datetime(2024, 1, 1, tzinfo=timezone.utc)
    for i in range(10):
        _seed_entry(db, uid, "text", base + timedelta(hours=i))
    db.commit()

    result = list_my_diary_entries(db=db, current_user=_make_user(uid), limit=3)

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

    result = list_my_diary_entries(db=db, current_user=_make_user(uid), offset=3)

    assert result.total == 5
    assert len(result.items) == 2
    assert result.offset == 3


def test_pagination_offset_beyond_total():
    eng = _build_engine()
    uid = uuid.uuid4()
    _seed_user(eng, uid)
    db = sessionmaker(bind=eng)()

    base = datetime(2024, 1, 1, tzinfo=timezone.utc)
    for i in range(3):
        _seed_entry(db, uid, "text", base + timedelta(hours=i))
    db.commit()

    result = list_my_diary_entries(db=db, current_user=_make_user(uid), offset=10)

    assert result.total == 3
    assert result.items == []


def test_ordering_most_recent_first():
    eng = _build_engine()
    uid = uuid.uuid4()
    _seed_user(eng, uid)
    db = sessionmaker(bind=eng)()

    base = datetime(2024, 1, 1, tzinfo=timezone.utc)
    for i in range(5):
        _seed_entry(db, uid, "text", base + timedelta(days=i))
    db.commit()

    result = list_my_diary_entries(db=db, current_user=_make_user(uid))

    recorded_ats = [item.recorded_at for item in result.items]
    assert recorded_ats == sorted(recorded_ats, reverse=True)


def test_filter_entry_type():
    eng = _build_engine()
    uid = uuid.uuid4()
    _seed_user(eng, uid)
    db = sessionmaker(bind=eng)()

    base = datetime(2024, 1, 1, tzinfo=timezone.utc)
    for i in range(3):
        _seed_entry(db, uid, "text", base + timedelta(hours=i))
    for i in range(2):
        _seed_entry(db, uid, "audio", base + timedelta(hours=10 + i))
    db.commit()

    result = list_my_diary_entries(db=db, current_user=_make_user(uid), entry_type=DiaryEntryType.text)

    assert result.total == 3
    assert all(item.entry_type == "text" for item in result.items)


def test_filter_entry_type_no_match():
    eng = _build_engine()
    uid = uuid.uuid4()
    _seed_user(eng, uid)
    db = sessionmaker(bind=eng)()

    base = datetime(2024, 1, 1, tzinfo=timezone.utc)
    for i in range(3):
        _seed_entry(db, uid, "text", base + timedelta(hours=i))
    db.commit()

    result = list_my_diary_entries(db=db, current_user=_make_user(uid), entry_type=DiaryEntryType.video)

    assert result.total == 0
    assert result.items == []


def test_filter_recorded_from():
    eng = _build_engine()
    uid = uuid.uuid4()
    _seed_user(eng, uid)
    db = sessionmaker(bind=eng)()

    base = datetime(2024, 1, 1, tzinfo=timezone.utc)
    for i in range(5):
        _seed_entry(db, uid, "text", base + timedelta(days=i))
    db.commit()

    cutoff = base + timedelta(days=2)
    result = list_my_diary_entries(db=db, current_user=_make_user(uid), recorded_from=cutoff)

    assert result.total == 3  # days 2, 3, 4


def test_filter_recorded_to():
    eng = _build_engine()
    uid = uuid.uuid4()
    _seed_user(eng, uid)
    db = sessionmaker(bind=eng)()

    base = datetime(2024, 1, 1, tzinfo=timezone.utc)
    for i in range(5):
        _seed_entry(db, uid, "text", base + timedelta(days=i))
    db.commit()

    cutoff = base + timedelta(days=2)
    result = list_my_diary_entries(db=db, current_user=_make_user(uid), recorded_to=cutoff)

    assert result.total == 3  # days 0, 1, 2


def test_filters_combined():
    eng = _build_engine()
    uid = uuid.uuid4()
    _seed_user(eng, uid)
    db = sessionmaker(bind=eng)()

    base = datetime(2024, 1, 1, tzinfo=timezone.utc)
    for i in range(10):
        _seed_entry(db, uid, "text", base + timedelta(days=i))
    for i in range(5):
        _seed_entry(db, uid, "audio", base + timedelta(days=i))
    db.commit()

    from_date = base + timedelta(days=2)
    to_date = base + timedelta(days=7)
    result = list_my_diary_entries(
        db=db,
        current_user=_make_user(uid),
        entry_type=DiaryEntryType.text,
        recorded_from=from_date,
        recorded_to=to_date,
        limit=3,
        offset=1,
    )

    # text entries on days 2–7 = 6 total; limit=3, offset=1 → 3 items
    assert result.total == 6
    assert len(result.items) == 3
    assert result.limit == 3
    assert result.offset == 1
    assert all(item.entry_type == "text" for item in result.items)


def test_only_own_entries_returned():
    eng = _build_engine()
    uid_a = uuid.uuid4()
    uid_b = uuid.uuid4()
    _seed_user(eng, uid_a)
    _seed_user(eng, uid_b)
    db = sessionmaker(bind=eng)()

    base = datetime(2024, 1, 1, tzinfo=timezone.utc)
    for i in range(3):
        _seed_entry(db, uid_a, "text", base + timedelta(hours=i))
    for i in range(5):
        _seed_entry(db, uid_b, "text", base + timedelta(hours=i))
    db.commit()

    result = list_my_diary_entries(db=db, current_user=_make_user(uid_a))

    assert result.total == 3


# ---------------------------------------------------------------------------
# 422 validation tests (via TestClient)
# ---------------------------------------------------------------------------

def test_422_limit_too_high():
    resp = _client.get("/api/v1/diary-entries/me?limit=101")
    assert resp.status_code == 422


def test_422_limit_zero():
    resp = _client.get("/api/v1/diary-entries/me?limit=0")
    assert resp.status_code == 422


def test_422_negative_offset():
    resp = _client.get("/api/v1/diary-entries/me?offset=-1")
    assert resp.status_code == 422


def test_422_malformed_recorded_from():
    resp = _client.get("/api/v1/diary-entries/me?recorded_from=not-a-date")
    assert resp.status_code == 422


def test_422_malformed_recorded_to():
    resp = _client.get("/api/v1/diary-entries/me?recorded_to=not-a-date")
    assert resp.status_code == 422


def test_422_unknown_entry_type():
    resp = _client.get("/api/v1/diary-entries/me?entry_type=unknown")
    assert resp.status_code == 422


def test_valid_request_returns_200():
    resp = _client.get(
        "/api/v1/diary-entries/me?limit=10&offset=0&entry_type=text"
        "&recorded_from=2024-01-01T00:00:00Z&recorded_to=2024-12-31T23:59:59Z"
    )
    assert resp.status_code == 200
    body = resp.json()
    assert "items" in body
    assert "total" in body
    assert body["limit"] == 10
    assert body["offset"] == 0
