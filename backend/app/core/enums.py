from enum import Enum


class UserRole(str, Enum):
    user = "user"
    admin = "admin"
    superadmin = "superadmin"


class AccessibilityProfile(str, Enum):
    none = "none"
    blind = "blind"
    low_vision = "low_vision"
    wheelchair = "wheelchair"
    wheelchair_biometric = "wheelchair_biometric"


class Language(str, Enum):
    pt = "pt"
    en = "en"


class ModelType(str, Enum):
    gltf = "gltf"
    glb = "glb"
    obj = "obj"
    fbx = "fbx"
    usdz = "usdz"


class MediaType(str, Enum):
    image = "image"
    audio = "audio"
    video = "video"
    image_360 = "image_360"
    video_360 = "video_360"


class LocationType(str, Enum):
    campus_entrance = "campus_entrance"
    building_entrance = "building_entrance"
    corridor_node = "corridor_node"
    room_node = "room_node"
    poi_node = "poi_node"
    stair_node = "stair_node"
    elevator_node = "elevator_node"
    outdoor_node = "outdoor_node"


class Direction(str, Enum):
    slight_left = "slight_left"
    left = "left"
    sharp_left = "sharp_left"
    straight = "straight"
    slight_right = "slight_right"
    right = "right"
    sharp_right = "sharp_right"
    u_turn = "u_turn"
    stairs_up = "stairs_up"
    stairs_down = "stairs_down"
    elevator_up = "elevator_up"
    elevator_down = "elevator_down"
    enter_building = "enter_building"
    exit = "exit"


class DiaryEntryType(str, Enum):
    text = "text"
    audio = "audio"
    image = "image"
    video = "video"


class NotificationStatus(str, Enum):
    pending = "pending"
    sent = "sent"
    read = "read"
    dismissed = "dismissed"


class GeofenceShape(str, Enum):
    circle = "circle"
    polygon = "polygon"