from pydantic import BaseModel
from uuid import UUID

class BeaconNavigationRequest(BaseModel):
    beacon_uuid: UUID
    target_location_id: UUID