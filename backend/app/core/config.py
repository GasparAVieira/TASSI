import os
from pathlib import Path


def load_env():
    env_path = Path(__file__).resolve().parents[2] / ".env"

    if not env_path.exists():
        print("⚠️ .env file not found")
        return

    with open(env_path, "r", encoding="utf-8") as f:
        for line in f:
            if "=" not in line or line.startswith("#"):
                continue

            key, value = line.strip().split("=", 1)
            os.environ.setdefault(key, value)


load_env()

class Settings:
    SECRET_KEY: str = os.getenv("SECRET_KEY")
    ALGORITHM: str = os.getenv("ALGORITHM")
    DATABASE_URL: str = os.getenv("DATABASE_URL")
    APP_NAME: str = os.getenv("APP_NAME")
    APP_VERSION: str = os.getenv("APP_VERSION", "1.0")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "60"))

    # --- Cloudflare R2 (S3-compatible object storage) ---
    # Account ID is the hex string in your R2 dashboard URL.
    R2_ACCOUNT_ID: str = os.getenv("R2_ACCOUNT_ID", "")
    R2_ACCESS_KEY_ID: str = os.getenv("R2_ACCESS_KEY_ID", "")
    R2_SECRET_ACCESS_KEY: str = os.getenv("R2_SECRET_ACCESS_KEY", "")
    R2_BUCKET: str = os.getenv("R2_BUCKET", "")
    # Public base URL for reads (no trailing slash). Either the r2.dev
    # dev subdomain (e.g. https://pub-xxxx.r2.dev) or your custom domain
    # (e.g. https://media.tassi.example). Required for public-read mode.
    R2_PUBLIC_BASE_URL: str = os.getenv("R2_PUBLIC_BASE_URL", "").rstrip("/")
    # Presigned upload URL TTL in seconds. 15 minutes is plenty for a
    # mobile client uploading a single audio/image/video file.
    R2_PRESIGN_TTL_SEC: int = int(os.getenv("R2_PRESIGN_TTL_SEC", "900"))

settings = Settings()