"""
Media upload router.

Single endpoint: POST /api/v1/media/upload-url

Flow:
  1. Flutter client calls this endpoint with {media_type, extension}.
  2. Backend issues a short-lived presigned PUT URL pointing at R2.
  3. Client PUTs the file straight to R2 with Content-Type set as
     instructed in `required_headers`.
  4. Client persists the returned `public_url` in diary_media.url
     when it later POSTs the diary entry.

The backend never sees the bytes — saves bandwidth on Render's free
tier and keeps the request cheap.
"""

from fastapi import APIRouter, Depends, HTTPException, status

from app.core.storage import (
    PresignedUpload,
    StorageError,
    StorageNotConfigured,
    generate_presigned_upload,
)
from app.dependencies import get_current_user
from app.models.user import User
from app.schemas.media import PresignUploadRequest, PresignUploadResponse


router = APIRouter(prefix="/api/v1/media", tags=["Media"])


@router.post(
    "/upload-url",
    response_model=PresignUploadResponse,
    status_code=status.HTTP_200_OK,
)
def create_upload_url(
    payload: PresignUploadRequest,
    current_user: User = Depends(get_current_user),
) -> PresignUploadResponse:
    try:
        result: PresignedUpload = generate_presigned_upload(
            user_id=current_user.id,
            media_type=payload.media_type,
            extension=payload.extension,
            entry_id=payload.entry_id,
            content_type=payload.content_type,
        )
    except ValueError as exc:
        # Bad media_type / extension combo.
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(exc),
        ) from exc
    except StorageNotConfigured as exc:
        # Server misconfiguration — surface as 503 so the client knows
        # to retry later rather than treating it as a bug in its request.
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(exc),
        ) from exc
    except StorageError as exc:
        # boto3/R2 round-trip failed.
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=str(exc),
        ) from exc

    return PresignUploadResponse(
        key=result.key,
        upload_url=result.upload_url,
        public_url=result.public_url,
        expires_in=result.expires_in,
        required_headers=result.required_headers,
    )
