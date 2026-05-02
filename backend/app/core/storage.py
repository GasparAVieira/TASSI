"""
Cloudflare R2 object storage helpers.

R2 exposes an S3-compatible API, so we use boto3 with a custom endpoint.
Two responsibilities live here:
  1. Issue short-lived presigned PUT URLs the Flutter app uses to upload
     a file directly to the bucket. The backend never proxies bytes.
  2. Build the stable public read URL (via R2_PUBLIC_BASE_URL) that the
     client persists in diary_media.url.

Configuration (set in .env, read via app.core.config.settings):
  R2_ACCOUNT_ID         — hex account id from the R2 dashboard
  R2_ACCESS_KEY_ID      — API token access key
  R2_SECRET_ACCESS_KEY  — API token secret
  R2_BUCKET             — bucket name
  R2_PUBLIC_BASE_URL    — e.g. https://pub-xxxx.r2.dev or custom domain
  R2_PRESIGN_TTL_SEC    — presign expiry, defaults to 900 (15 min)

The boto3 client is created lazily so the module imports cleanly even
when R2 credentials are missing (useful during local development and
tests that don't touch storage).
"""

from __future__ import annotations

import uuid
from dataclasses import dataclass
from typing import Optional

import boto3
from botocore.client import Config
from botocore.exceptions import BotoCoreError, ClientError

from app.core.config import settings


# ---------------------------------------------------------------------------
# Allowed extensions per media_type. Mirrors the diary_media.media_type
# enum used elsewhere in the schema (image | audio | video). We keep the
# whitelist small and explicit — easier to reason about than a generic
# MIME match, and the Flutter recorders / pickers only produce a handful
# of formats anyway.
# ---------------------------------------------------------------------------
ALLOWED_EXTENSIONS: dict[str, set[str]] = {
    "image": {"jpg", "jpeg", "png", "webp", "heic"},
    "audio": {"m4a", "mp3", "aac", "wav", "ogg"},
    "video": {"mp4", "mov", "webm"},
}

DEFAULT_CONTENT_TYPES: dict[str, str] = {
    "jpg": "image/jpeg",
    "jpeg": "image/jpeg",
    "png": "image/png",
    "webp": "image/webp",
    "heic": "image/heic",
    "m4a": "audio/mp4",
    "mp3": "audio/mpeg",
    "aac": "audio/aac",
    "wav": "audio/wav",
    "ogg": "audio/ogg",
    "mp4": "video/mp4",
    "mov": "video/quicktime",
    "webm": "video/webm",
}


class StorageNotConfigured(RuntimeError):
    """Raised when an R2 operation is requested but config is incomplete."""


class StorageError(RuntimeError):
    """Wraps boto3/botocore errors so the router can return a 502 cleanly."""


@dataclass(frozen=True)
class PresignedUpload:
    key: str
    upload_url: str
    public_url: str
    expires_in: int
    required_headers: dict[str, str]


# ---------------------------------------------------------------------------
# Lazy client. We don't instantiate boto3 at import time so the module
# loads even when env vars are missing (e.g. CI, contributor's first run).
# ---------------------------------------------------------------------------
_client = None


def _is_configured() -> bool:
    return bool(
        settings.R2_ACCOUNT_ID
        and settings.R2_ACCESS_KEY_ID
        and settings.R2_SECRET_ACCESS_KEY
        and settings.R2_BUCKET
    )


def _get_client():
    global _client
    if _client is not None:
        return _client

    if not _is_configured():
        raise StorageNotConfigured(
            "R2 is not configured. Set R2_ACCOUNT_ID, R2_ACCESS_KEY_ID, "
            "R2_SECRET_ACCESS_KEY and R2_BUCKET in the backend .env."
        )

    endpoint = f"https://{settings.R2_ACCOUNT_ID}.r2.cloudflarestorage.com"

    # Signature v4 is required by R2. 'auto' region works because R2
    # is single-region from the client's perspective.
    _client = boto3.client(
        "s3",
        endpoint_url=endpoint,
        aws_access_key_id=settings.R2_ACCESS_KEY_ID,
        aws_secret_access_key=settings.R2_SECRET_ACCESS_KEY,
        region_name="auto",
        config=Config(signature_version="s3v4"),
    )
    return _client


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
def _normalise_extension(filename_or_ext: str) -> str:
    ext = filename_or_ext.rsplit(".", 1)[-1] if "." in filename_or_ext else filename_or_ext
    return ext.lower().strip()


def build_object_key(
    *,
    user_id: uuid.UUID,
    media_type: str,
    extension: str,
    entry_id: Optional[uuid.UUID] = None,
) -> str:
    """
    Object key layout:
        diary/{user_id}/{entry_id_or_unbound}/{uuid4}.{ext}

    Including the user id makes ownership obvious in the bucket and keeps
    listings tidy. We use a fresh uuid4 for the filename so two clients
    can't collide and so the key is never guessable.
    """
    bucket_segment = str(entry_id) if entry_id else "unbound"
    obj_uuid = uuid.uuid4()
    return f"diary/{user_id}/{bucket_segment}/{obj_uuid}.{extension}"


def validate_media_request(media_type: str, extension: str) -> str:
    """
    Returns the normalised extension on success, raises ValueError otherwise.
    Caller (router) should turn ValueError into a 400 response.
    """
    if media_type not in ALLOWED_EXTENSIONS:
        raise ValueError(
            f"media_type must be one of {sorted(ALLOWED_EXTENSIONS)} (got '{media_type}')"
        )
    ext = _normalise_extension(extension)
    if ext not in ALLOWED_EXTENSIONS[media_type]:
        raise ValueError(
            f"extension '{ext}' not allowed for media_type '{media_type}'. "
            f"Allowed: {sorted(ALLOWED_EXTENSIONS[media_type])}"
        )
    return ext


def build_public_url(key: str) -> str:
    if not settings.R2_PUBLIC_BASE_URL:
        raise StorageNotConfigured(
            "R2_PUBLIC_BASE_URL is not set; cannot build a public read URL."
        )
    return f"{settings.R2_PUBLIC_BASE_URL}/{key}"


def generate_presigned_upload(
    *,
    user_id: uuid.UUID,
    media_type: str,
    extension: str,
    entry_id: Optional[uuid.UUID] = None,
    content_type: Optional[str] = None,
) -> PresignedUpload:
    """
    Generate a presigned PUT URL the client can upload to directly.

    The client MUST send the same Content-Type header it was given here,
    otherwise S3/R2 will reject the signature. We return the headers the
    client must echo so the Flutter side doesn't have to guess.
    """
    ext = validate_media_request(media_type, extension)
    resolved_content_type = content_type or DEFAULT_CONTENT_TYPES.get(
        ext, "application/octet-stream"
    )

    key = build_object_key(
        user_id=user_id,
        media_type=media_type,
        extension=ext,
        entry_id=entry_id,
    )

    client = _get_client()
    ttl = max(60, settings.R2_PRESIGN_TTL_SEC)

    try:
        upload_url = client.generate_presigned_url(
            ClientMethod="put_object",
            Params={
                "Bucket": settings.R2_BUCKET,
                "Key": key,
                "ContentType": resolved_content_type,
            },
            ExpiresIn=ttl,
            HttpMethod="PUT",
        )
    except (BotoCoreError, ClientError) as exc:
        raise StorageError(f"Failed to presign upload URL: {exc}") from exc

    return PresignedUpload(
        key=key,
        upload_url=upload_url,
        public_url=build_public_url(key),
        expires_in=ttl,
        required_headers={"Content-Type": resolved_content_type},
    )
