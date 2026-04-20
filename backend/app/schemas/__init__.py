from app.schemas.user import UserCreate, UserResponse, LoginRequest, TokenResponse
from app.schemas.building import BuildingCreate, BuildingResponse, BuildingUpdate
from app.schemas.location import LocationCreate, LocationResponse, LocationUpdate
from app.schemas.room import RoomCreate, RoomResponse, RoomUpdate
from app.schemas.beacon import BeaconCreate, BeaconResponse, BeaconUpdate
from app.schemas.path import PathCreate, PathResponse, PathUpdate
from app.schemas.route import RouteCreate, RouteResponse, RouteUpdate
from app.schemas.route_step import RouteStepCreate, RouteStepResponse, RouteStepUpdate
from app.schemas.point_of_interest import (
    PointOfInterestCreate,
    PointOfInterestResponse,
    PointOfInterestUpdate,
)
from app.schemas.poi_media import PoiMediaCreate, PoiMediaResponse, PoiMediaUpdate
from app.schemas.faq import FaqCreate, FaqResponse, FaqUpdate