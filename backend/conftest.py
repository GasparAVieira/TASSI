import os
import sys
from unittest.mock import MagicMock

# Environment variables required before any app import
os.environ.setdefault("DATABASE_URL", "sqlite://")
os.environ.setdefault("SECRET_KEY", "test-secret")
os.environ.setdefault("ALGORITHM", "HS256")
os.environ.setdefault("APP_NAME", "test")

# --- stub native packages not installed in this environment ---
sys.modules.setdefault("bcrypt", MagicMock())
sys.modules.setdefault("jose", MagicMock())
sys.modules.setdefault("jose.jwt", MagicMock())
sys.modules.setdefault("psycopg", MagicMock())

# --- replace app.database with a real SQLite-backed module ---
# This must happen before any model or router is imported so that
# `from app.database import Base` resolves to our test Base.
import types
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

_test_engine = create_engine("sqlite://", connect_args={"check_same_thread": False})
_TestBase = declarative_base()
_TestSession = sessionmaker(bind=_test_engine)

_db_mod = types.ModuleType("app.database")
_db_mod.engine = _test_engine
_db_mod.Base = _TestBase
_db_mod.SessionLocal = _TestSession
_db_mod.get_db = MagicMock()
sys.modules["app.database"] = _db_mod

sys.path.insert(0, os.path.dirname(__file__))
