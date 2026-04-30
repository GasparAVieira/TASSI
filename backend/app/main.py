import asyncio
from contextlib import asynccontextmanager
from fastapi import FastAPI

from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.database import Base, engine
from app.routers import auth, buildings, locations, navigation, paths, rooms, users, diary_entries, notifications, notification_socket, epoc_session, epoc_router, admin_diary, admin_users
from app.jobs.notification_scheduler import notification_scheduler_loop

from app.notifications import rules

Base.metadata.create_all(bind=engine)

@asynccontextmanager
async def lifespan(app: FastAPI):
    scheduler_task = asyncio.create_task(notification_scheduler_loop())

    yield

    scheduler_task.cancel()

app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    lifespan=lifespan   
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:8000",
        "http://localhost:5500",
        "https://tassi.onrender.com:",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
def health_check():
    return {"status": "ok"}

app.include_router(auth.router)
app.include_router(users.router)
app.include_router(buildings.router)
app.include_router(locations.router)
app.include_router(rooms.router)
app.include_router(paths.router)
app.include_router(navigation.router)
app.include_router(diary_entries.router)
app.include_router(notifications.router)
app.include_router(notification_socket.router)
app.include_router(epoc_router.router)
app.include_router(epoc_session.router)
app.include_router(admin_diary.router)
app.include_router(admin_users.router)