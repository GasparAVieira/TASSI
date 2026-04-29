from datetime import datetime, timezone

import pytest
from fastapi import HTTPException

from app.routers.diary_entries import validate_diary_entry_payload
from app.schemas.diary_entry import DiaryEntryCreate
from app.schemas.diary_media import DiaryMediaCreate

_NOW = datetime.now(timezone.utc)


def _text(body=None, media_items=None):
    return DiaryEntryCreate(
        entry_type="text",
        body=body,
        recorded_at=_NOW,
        media_items=media_items or [],
    )


def _media(entry_type, media_type):
    return DiaryEntryCreate(
        entry_type=entry_type,
        recorded_at=_NOW,
        media_items=[DiaryMediaCreate(media_type=media_type, url="http://x/y")],
    )


# --- text entries ---

def test_text_with_body_passes():
    validate_diary_entry_payload(_text(body="hello"))


def test_text_without_body_raises():
    with pytest.raises(HTTPException) as exc:
        validate_diary_entry_payload(_text(body=None))
    assert exc.value.status_code == 400


def test_text_with_media_raises():
    media = DiaryMediaCreate(media_type="image", url="http://x/y")
    with pytest.raises(HTTPException) as exc:
        validate_diary_entry_payload(_text(body="hi", media_items=[media]))
    assert exc.value.status_code == 400


# --- media entries ---

def test_audio_with_audio_media_passes():
    validate_diary_entry_payload(_media("audio", "audio"))


def test_audio_without_media_raises():
    payload = DiaryEntryCreate(entry_type="audio", recorded_at=_NOW, media_items=[])
    with pytest.raises(HTTPException) as exc:
        validate_diary_entry_payload(payload)
    assert exc.value.status_code == 400


def test_audio_with_wrong_media_type_raises():
    with pytest.raises(HTTPException) as exc:
        validate_diary_entry_payload(_media("audio", "image"))
    assert exc.value.status_code == 400


def test_image_with_image_media_passes():
    validate_diary_entry_payload(_media("image", "image"))


def test_video_with_video_media_passes():
    validate_diary_entry_payload(_media("video", "video"))
