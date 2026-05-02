"""
End-to-end smoke test for the media upload pipeline.

Exercises the same flow the Flutter app will follow:
  1. POST /api/v1/auth/login                       -> JWT
  2. POST /api/v1/media/upload-url                 -> presigned PUT
  3. PUT  <upload_url>  (file bytes + Content-Type) -> R2 stores it
  4. GET  <public_url>                              -> verifies the bytes

Run from the backend folder while the FastAPI app is running locally:

    # terminal 1
    uvicorn app.main:app --reload

    # terminal 2
    python smoke_test_media_e2e.py --email you@example.com --password ...

Add --register to create the user first if it doesn't exist.
"""
from __future__ import annotations

import argparse
import json
import sys
import time
import urllib.error
import urllib.request


BROWSER_UA = "Mozilla/5.0 (smoke-test) tassi/1.0"


def _request(method: str, url: str, *, body: bytes | None = None, headers: dict | None = None, timeout: int = 20):
    req = urllib.request.Request(url, data=body, method=method)
    req.add_header("User-Agent", BROWSER_UA)
    for k, v in (headers or {}).items():
        req.add_header(k, v)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return r.status, r.read(), dict(r.headers)
    except urllib.error.HTTPError as e:
        return e.code, e.read(), dict(e.headers or {})


def login(base: str, email: str, password: str) -> str | None:
    body = json.dumps({"email": email, "password": password}).encode()
    code, raw, _ = _request(
        "POST",
        f"{base}/api/v1/auth/login",
        body=body,
        headers={"Content-Type": "application/json"},
    )
    if code != 200:
        print(f"FAIL: login -> HTTP {code}: {raw[:200].decode(errors='replace')}")
        return None
    return json.loads(raw)["access_token"]


def register(base: str, email: str, password: str, full_name: str) -> bool:
    body = json.dumps({"email": email, "password": password, "full_name": full_name}).encode()
    code, raw, _ = _request(
        "POST",
        f"{base}/api/v1/auth/register",
        body=body,
        headers={"Content-Type": "application/json"},
    )
    if code in (200, 201):
        return True
    if code == 400 and b"already" in raw.lower():
        return True  # user already exists, fine
    print(f"register -> HTTP {code}: {raw[:200].decode(errors='replace')}")
    return False


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--base", default="http://127.0.0.1:8000")
    p.add_argument("--email", required=True)
    p.add_argument("--password", required=True)
    p.add_argument("--full-name", default="Smoke Tester")
    p.add_argument("--register", action="store_true", help="create the user first if missing")
    args = p.parse_args()

    if args.register:
        if not register(args.base, args.email, args.password, args.full_name):
            print("FAIL: register")
            return 1

    print("[1/5] login                                       ...", end=" ", flush=True)
    token = login(args.base, args.email, args.password)
    if not token:
        return 1
    print("OK")

    print("[2/5] POST /api/v1/media/upload-url               ...", end=" ", flush=True)
    body = json.dumps({"media_type": "audio", "extension": "m4a"}).encode()
    code, raw, _ = _request(
        "POST",
        f"{args.base}/api/v1/media/upload-url",
        body=body,
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {token}",
        },
    )
    if code != 200:
        print(f"\nFAIL: upload-url -> HTTP {code}: {raw[:300].decode(errors='replace')}")
        return 1
    presign = json.loads(raw)
    print("OK")
    print(f"      key        = {presign['key']}")
    print(f"      public_url = {presign['public_url']}")
    print(f"      expires_in = {presign['expires_in']}s")

    print("[3/5] PUT bytes to upload_url                     ...", end=" ", flush=True)
    payload = b"hello from the e2e smoke test\n"
    headers = dict(presign["required_headers"])
    headers["Content-Length"] = str(len(payload))
    code, raw, _ = _request("PUT", presign["upload_url"], body=payload, headers=headers, timeout=30)
    if code not in (200, 204):
        print(f"\nFAIL: PUT to R2 -> HTTP {code}: {raw[:300].decode(errors='replace')}")
        print("       SignatureDoesNotMatch usually means Content-Type mismatch.")
        return 1
    print("OK")

    print("[4/5] GET public_url verifies bytes               ...", end=" ", flush=True)
    time.sleep(2)
    code, raw, _ = _request("GET", presign["public_url"], timeout=15)
    if code != 200:
        print(f"\nFAIL: public GET -> HTTP {code}")
        return 1
    if raw != payload:
        print("\nFAIL: public GET returned different bytes")
        return 1
    print("OK")

    print("[5/5] done                                        OK")
    print()
    print("End-to-end pipeline works. The Flutter team can build against this contract.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
