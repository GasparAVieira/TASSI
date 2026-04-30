from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, EmailStr

from app.core.enums import AccessibilityProfile, Language, UserRole


class UserBase(BaseModel):
    full_name: str
    email: EmailStr
    phone: str | None = None
    bio: str | None = None
    accessibility_profile: AccessibilityProfile = AccessibilityProfile.none
    preferred_language: Language = Language.pt
    audio_guidance: bool = False


class UserCreate(UserBase):
    password: str


class UserUpdate(BaseModel):
    full_name: str | None = None
    email: EmailStr | None = None
    phone: str | None = None
    bio: str | None = None
    accessibility_profile: AccessibilityProfile | None = None
    preferred_language: Language | None = None
    audio_guidance: bool | None = None


class RoleUpdate(BaseModel):
    role: UserRole


class UserResponse(UserBase):
    id: UUID
    role: UserRole
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse