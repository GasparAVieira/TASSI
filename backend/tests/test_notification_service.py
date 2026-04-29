from datetime import datetime, timezone
from unittest.mock import MagicMock, patch
from uuid import uuid4

from app.services.notification_service import user_has_diary_today


def _make_user(user_id=None):
    user = MagicMock()
    user.id = user_id or uuid4()
    return user


def _mock_db(query_result):
    """Return a db session mock whose query chain resolves to query_result."""
    db = MagicMock()
    db.query.return_value.filter.return_value.first.return_value = query_result
    return db


def test_user_has_diary_today_true():
    user = _make_user()
    db = _mock_db(query_result=MagicMock())  # some entry found
    assert user_has_diary_today(db, user) is True


def test_user_has_diary_today_false():
    user = _make_user()
    db = _mock_db(query_result=None)  # no entry today
    assert user_has_diary_today(db, user) is False


def test_user_has_diary_today_queries_correct_model():
    from app.models.diary_entry import DiaryEntry

    user = _make_user()
    db = _mock_db(query_result=None)

    user_has_diary_today(db, user)

    db.query.assert_called_once_with(DiaryEntry)
