"""
Verifies that the registration endpoint always creates a user-role account,
regardless of any role value included in the request payload.

The UserCreate schema has no 'role' field, so any supplied value is silently
dropped by Pydantic. The router hardcodes role=UserRole.user on every
registration, making self-elevation impossible through this endpoint.
"""
import uuid
from unittest.mock import patch

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.routers import auth as auth_module
from app.models.user import User  # triggers mapper; EpocSession must also be imported
from app.models.epoc_session import EpocSession  # registers mapper (required by User relationship)
from app.database import get_db


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _build_engine():
    eng = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
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
        conn.commit()
    return eng


_eng = _build_engine()
_Session = sessionmaker(bind=_eng)


def _db_override():
    db = _Session()
    try:
        yield db
    finally:
        db.close()


_app = FastAPI()
_app.include_router(auth_module.router)
_app.dependency_overrides[get_db] = _db_override
_client = TestClient(_app)

# Reusable patch context: bypass bcrypt and jose stubs so registration
# produces clean string values that Pydantic can serialize.
_SECURITY_PATCHES = (
    patch("app.routers.auth.hash_password", return_value="hashed-pw"),
    patch("app.routers.auth.create_access_token", return_value="test-token"),
)


def _register(payload: dict):
    with patch("app.routers.auth.hash_password", return_value="hashed-pw"), \
         patch("app.routers.auth.create_access_token", return_value="test-token"):
        return _client.post("/api/v1/auth/register", json=payload)


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

def test_register_with_role_admin_in_payload_creates_user_role():
    resp = _register({
        "full_name": "Malicious Admin",
        "email": "malicious@example.com",
        "password": "password123",
        "role": "admin",
    })
    assert resp.status_code == 201
    assert resp.json()["user"]["role"] == "user"


def test_register_with_role_superadmin_in_payload_creates_user_role():
    resp = _register({
        "full_name": "Super Hacker",
        "email": "hacker@example.com",
        "password": "password123",
        "role": "superadmin",
    })
    assert resp.status_code == 201
    assert resp.json()["user"]["role"] == "user"


def test_register_without_role_field_creates_user_role():
    resp = _register({
        "full_name": "Regular Person",
        "email": "regular@example.com",
        "password": "password123",
    })
    assert resp.status_code == 201
    assert resp.json()["user"]["role"] == "user"


def test_register_returns_access_token():
    resp = _register({
        "full_name": "Token Test",
        "email": "tokentest@example.com",
        "password": "password123",
    })
    assert resp.status_code == 201
    body = resp.json()
    assert body["access_token"] == "test-token"
    assert body["token_type"] == "bearer"


def test_register_duplicate_email_returns_400():
    _register({
        "full_name": "First",
        "email": "dup@example.com",
        "password": "password123",
    })
    resp = _register({
        "full_name": "Second",
        "email": "dup@example.com",
        "password": "password123",
    })
    assert resp.status_code == 400
