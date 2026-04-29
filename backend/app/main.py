import asyncio
from fastapi import FastAPI

from app.core.config import settings
from app.database import Base, engine
from app.routers import auth, buildings, locations, navigation, paths, rooms, users, diary_entries, notifications, notification_socket, epoc_router
from app.jobs.notification_scheduler import notification_scheduler_loop

Base.metadata.create_all(bind=engine)

app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
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