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

settings = Settings()