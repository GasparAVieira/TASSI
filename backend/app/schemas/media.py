"""Schemas for media upload presigning."""

from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field
from typing_extensions import Literal


class PresignUploadRequest(BaseModel):
    media_type: Literal["audio", "image", "video"]
    # Either a full filename ("clip.m4a") or just the extension ("m4a").
    # Validation strips everything before the last dot.
    extension: str = Field(min_length=1, max_length=16)
    # Optional. If omitted we infer from extension.
    content_type: Optional[str] = Field(default=None, max_length=100)
    # Optional. When set, the object key is namespaced under this entry_id
    # so listings group by diary entry. Use 'unbound' (i.e. omit) when the
    # entry doesn't exist yet — common case for new entries since the
    # client uploads media first, then POSTs the entry referencing the
    # public URLs.
    entry_id: Optional[UUID] = None


class PresignUploadResponse(BaseModel):
    key: str
    upload_url: str
    public_url: str
    expires_in: int
    # Headers the client must echo when PUTting the file. At minimum
    # Content-Type — required for the signature to verify.
    required_headers: dict[str, str]
