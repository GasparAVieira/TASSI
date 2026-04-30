import json
import ssl
import uuid
import time
from typing import Optional

import websocket

class EpocService:
    def __init__(self, client_id: str, client_secret: str):
        self.client_id = client_id
        self.client_secret = client_secret
        self.ws: Optional[websocket.WebSocket] = None
        self.auth_token: Optional[str] = None
        self.session_id: Optional[str] = None
        self.headset_id: Optional[str] = None

    def connect(self):
        self.ws = websocket.create_connection(
            "wss://192.168.1.245:6868",
            sslopt={"cert_reqs": ssl.CERT_NONE},
        )

    def _send_request(self, method: str, params: dict):
        request_id = str(uuid.uuid4())

        payload = {
            "jsonrpc": "2.0",
            "method": method,
            "params": params,
            "id": request_id,
        }

        self.ws.send(json.dumps(payload))
        response = json.loads(self.ws.recv())

        if "error" in response:
            raise Exception(response["error"])

        return response.get("result", response)

    def request_access(self):
        return self._send_request(
            "requestAccess",
            {
                "clientId": self.client_id,
                "clientSecret": self.client_secret,
            },
        )
    
    def authorize(self):
        result = self._send_request(
            "authorize",
            {
                "clientId": self.client_id,
                "clientSecret": self.client_secret,
                "debit": 50,
            },
        )

        self.auth_token = result["cortexToken"]
        return self.auth_token

    def query_headsets(self):
        result = self._send_request("queryHeadsets", {})

        if not result:
            raise Exception("No headset detected")

        self.headset_id = result[0]["id"]
        return result

    def control_device(self, command: str = "connect"):
        return self._send_request(
            "controlDevice",
            {
                "command": command,
                "headset": self.headset_id,
            },
        )

    def create_session(self):
        result = self._send_request(
            "createSession",
            {
                "cortexToken": self.auth_token,
                "headset": self.headset_id,
                "status": "active",
            },
        )

        self.session_id = result["id"]
        return result
    
    def subscribe(self, streams: list[str]):
        return self._send_request(
            "subscribe",
            {
                "cortexToken": self.auth_token,
                "session": self.session_id,
                "streams": streams,
            },
        )

    def receive_data(self):
        while True:
            data = json.loads(self.ws.recv())
            yield data

    def close(self):
        if self.ws:
            self.ws.close()