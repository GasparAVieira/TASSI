from app.schemas.beacon import BeaconCreate, BeaconResponse, BeaconUpdate
from app.schemas.building import BuildingCreate, BuildingResponse, BuildingUpdate
from app.schemas.location import LocationCreate, LocationResponse, LocationUpdate
from app.schemas.navigation import NavigationRouteRequest, NavigationRouteResponse, NavigationStep
from app.schemas.path import PathCreate, PathResponse, PathUpdate
from app.schemas.room import RoomCreate, RoomResponse, RoomUpdate
from app.schemas.user import (
    LoginRequest,
    TokenResponse,
    UserCreate,
    UserResponse,
    UserUpdate,
)
from app.schemas.route import RouteCreate, RouteResponse, RouteUpdate
from app.schemas.route_step import RouteStepCreate, RouteStepResponse, RouteStepUpdate