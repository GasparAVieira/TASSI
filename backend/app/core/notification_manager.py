from uuid import UUID
from fastapi import WebSocket


class NotificationConnectionManager:
    def __init__(self):
        self.active_connections: dict[UUID, list[WebSocket]] = {}

    async def connect(self, user_id: UUID, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.setdefault(user_id, []).append(websocket)

    def disconnect(self, user_id: UUID, websocket: WebSocket):
        connections = self.active_connections.get(user_id, [])

        if websocket in connections:
            connections.remove(websocket)

        if not connections:
            self.active_connections.pop(user_id, None)

    async def send_to_user(self, user_id: UUID, payload: dict):
        connections = self.active_connections.get(user_id, [])

        for websocket in connections.copy():
            try:
                await websocket.send_json(payload)
            except Exception:
                self.disconnect(user_id, websocket)


notification_manager = NotificationConnectionManager()