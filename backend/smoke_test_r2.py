"""
R2 smoke test. Run from the backend folder:

    python smoke_test_r2.py

Reads creds from backend/.env, uploads a tiny file with boto3, fetches it
through the public URL, then deletes it. Prints OK / FAIL for each step.
Never prints secret values — safe to share output in chat.
"""
import os
import sys
import time
import uuid
import urllib.error
import urllib.request
from pathlib import Path


def main() -> int:
    env_path = Path(__file__).parent / ".env"
    if not env_path.exists():
        print("FAIL: backend/.env not found")
        return 1

    for raw in env_path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, v = line.split("=", 1)
        # Strip surrounding quotes if user wrapped values
        v = v.strip()
        if (v.startswith('"') and v.endswith('"')) or (v.startswith("'") and v.endswith("'")):
            v = v[1:-1]
        os.environ.setdefault(k.strip(), v)

    required = [
        "R2_ACCOUNT_ID",
        "R2_ACCESS_KEY_ID",
        "R2_SECRET_ACCESS_KEY",
        "R2_BUCKET",
        "R2_PUBLIC_BASE_URL",
    ]
    missing = [k for k in required if not os.environ.get(k)]
    if missing:
        print("FAIL: missing keys in .env:", ", ".join(missing))
        return 1
    print("[1/5] .env keys present                          OK")

    try:
        import boto3
        from botocore.client import Config
        from botocore.exceptions import ClientError, EndpointConnectionError
    except ImportError:
        print("FAIL: boto3 not installed. Run: pip install -r requirements-win.txt")
        return 1

    acct = os.environ["R2_ACCOUNT_ID"]
    bucket = os.environ["R2_BUCKET"]
    pub = os.environ["R2_PUBLIC_BASE_URL"].rstrip("/")

    client = boto3.client(
        "s3",
        endpoint_url=f"https://{acct}.r2.cloudflarestorage.com",
        aws_access_key_id=os.environ["R2_ACCESS_KEY_ID"],
        aws_secret_access_key=os.environ["R2_SECRET_ACCESS_KEY"],
        region_name="auto",
        config=Config(signature_version="s3v4"),
    )

    try:
        client.head_bucket(Bucket=bucket)
    except ClientError as e:
        code = e.response.get("Error", {}).get("Code")
        msg = e.response.get("Error", {}).get("Message", "")
        print(f"FAIL: head_bucket -> {code}: {msg}")
        print("       403 = bad keys / token not scoped to this bucket")
        print("       404 = bucket name typo or wrong account")
        return 1
    except EndpointConnectionError as e:
        print(f"FAIL: cannot reach R2 endpoint — check R2_ACCOUNT_ID. {e}")
        return 1
    print("[2/5] head_bucket succeeded (creds + bucket OK)  OK")

    key = f"diagnostics/smoke-{uuid.uuid4()}.txt"
    body = b"tassi r2 smoke test ok\n"
    try:
        client.put_object(Bucket=bucket, Key=key, Body=body, ContentType="text/plain")
    except ClientError as e:
        print(f"FAIL: put_object -> {e}")
        return 1
    print("[3/5] put_object                                 OK")

    public_url = f"{pub}/{key}"
    time.sleep(2)
    # Cloudflare's edge filters out python-urllib UA on r2.dev URLs (bot
    # protection), so we send a normal browser UA. This has no effect on
    # how the Flutter app will fetch the URL — http_client / dio set their
    # own UAs, both of which Cloudflare allows.
    req = urllib.request.Request(
        public_url,
        headers={"User-Agent": "Mozilla/5.0 (smoke-test) tassi/1.0"},
    )
    try:
        with urllib.request.urlopen(req, timeout=15) as r:
            data = r.read()
            if data != body:
                print("FAIL: public GET returned different bytes")
                return 1
    except urllib.error.HTTPError as e:
        print(f"FAIL: public GET -> HTTP {e.code}.")
        if e.code == 404:
            print("       File not found at public URL — Public Development URL")
            print("       may not have propagated yet. Wait 30s and re-run.")
        elif e.code == 403:
            print("       Even with a browser User-Agent, the GET was blocked.")
            print("       Check that 'Public Development URL' is toggled on")
            print("       in the bucket Settings tab.")
        return 1
    except Exception as e:
        print(f"FAIL: public GET -> {e}")
        return 1
    print("[4/5] public GET round-trips identical bytes     OK")

    client.delete_object(Bucket=bucket, Key=key)
    print("[5/5] cleanup delete_object                      OK")
    print()
    print("ALL GOOD — R2 is wired correctly.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
