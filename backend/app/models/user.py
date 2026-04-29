import uuid

from sqlalchemy import Boolean, DateTime, Enum, Text, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.enums import AccessibilityProfile, Language, UserRole
from app.database import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
    )
    full_name: Mapped[str] = mapped_column(Text, nullable=False)
    email: Mapped[str] = mapped_column(Text, nullable=False, unique=True, index=True)
    password_hash: Mapped[str] = mapped_column(Text, nullable=False)
    phone: Mapped[str | None] = mapped_column(Text, nullable=True)
    bio: Mapped[str | None] = mapped_column(Text, nullable=True)

    role: Mapped[UserRole] = mapped_column(
        Enum(UserRole, name="user_role"),
        nullable=False,
        default=UserRole.user,
    )
    accessibility_profile: Mapped[AccessibilityProfile] = mapped_column(
        Enum(AccessibilityProfile, name="accessibility_profile_enum"),
        nullable=False,
        default=AccessibilityProfile.none,
    )
    preferred_language: Mapped[Language] = mapped_column(
        Enum(Language, name="language_enum"),
        nullable=False,
        default=Language.pt,
    )
    audio_guidance: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        default=False,
    )

    created_at: Mapped[DateTime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )
    updated_at: Mapped[DateTime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
        onupdate=func.now(),
    )

    diary_entries = relationship("DiaryEntry", back_populates="participant", cascade="all, delete-orphan")
    epoc_sessions = relationship("EpocSession",back_populates="participant",cascade="all, delete-orphan",)
    