from fastapi import FastAPI

from app.config import settings
from app.database import Base, engine
from app.routers import auth, beacons, buildings, locations, navigation, paths, rooms, routes, route_steps, users
import app.models


Base.metadata.create_all(bind=engine)

app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
)


@app.get("/health")
def health_check():
    return {"status": "ok"}


app.include_router(auth.router)
app.include_router(users.router)
app.include_router(buildings.router)
app.include_router(locations.router)
app.include_router(rooms.router)
app.include_router(beacons.router)
app.include_router(paths.router)
app.include_router(navigation.router)
app.include_router(routes.router)
app.include_router(route_steps.router)