# Media uploads — Cloudflare R2 setup

This guide walks through enabling media uploads (audio/image/video) for diary
entries. Storage uses **Cloudflare R2** (S3-compatible, 10 GB free, no egress
fees). The Flutter client uploads files **directly** to R2 via short-lived
presigned URLs the backend issues — the API never proxies bytes.

---

## 1. Cloudflare side (one-time)

1. **Create a bucket.** Cloudflare dashboard → R2 → *Create bucket*.
   - Name: `tassi-media` (or whatever — it goes in `R2_BUCKET`).
   - Location: *Automatic*.
2. **Make it public for reads.** In the bucket → *Settings* → *Public access*.
   - Easiest: enable the **r2.dev** dev subdomain. You'll get a URL like
     `https://pub-<hash>.r2.dev`. Use that as `R2_PUBLIC_BASE_URL`.
   - For production: connect a custom domain (e.g. `media.tassi.example`)
     and use that as `R2_PUBLIC_BASE_URL`.
3. **Create an API token.** R2 → *Manage R2 API Tokens* → *Create API Token*.
   - Permissions: **Object Read & Write**.
   - Bucket: scope to your bucket only.
   - Save the **Access Key ID** and **Secret Access Key** — Cloudflare shows
     the secret once.
4. **Find your account ID.** It's the hex string in the dashboard URL
   (`https://dash.cloudflare.com/<ACCOUNT_ID>/...`).
5. **CORS.** In the bucket → *Settings* → *CORS Policy*, paste:
   ```json
   [
     {
       "AllowedOrigins": ["*"],
       "AllowedMethods": ["PUT", "GET"],
       "AllowedHeaders": ["Content-Type"],
       "MaxAgeSeconds": 3600
     }
   ]
   ```
   Tighten `AllowedOrigins` to your actual app origins before going to prod.

---

## 2. Backend `.env`

Add the following keys (don't commit the secret):

```
R2_ACCOUNT_ID=<account hex id>
R2_ACCESS_KEY_ID=<token access key>
R2_SECRET_ACCESS_KEY=<token secret>
R2_BUCKET=tassi-media
R2_PUBLIC_BASE_URL=https://pub-xxxxxxxxxxxx.r2.dev
R2_PRESIGN_TTL_SEC=900
```

Then install the new dependency:

```
pip install -r requirements-win.txt   # or requirements-linux.txt
```

(`boto3` is the only new package.)

---

## 3. API contract

### `POST /api/v1/media/upload-url`

Auth: `Authorization: Bearer <jwt>` (same as the rest of the API).

Request body:

```json
{
  "media_type": "audio",     // "audio" | "image" | "video"
  "extension":  "m4a",       // or full filename like "clip.m4a"
  "content_type": null,      // optional override; inferred from extension
  "entry_id": null           // optional; if known, groups objects by entry
}
```

Response 200:

```json
{
  "key": "diary/<user_id>/<entry_or_unbound>/<uuid>.m4a",
  "upload_url": "https://<account>.r2.cloudflarestorage.com/...signed...",
  "public_url": "https://pub-xxxx.r2.dev/diary/<user_id>/.../<uuid>.m4a",
  "expires_in": 900,
  "required_headers": { "Content-Type": "audio/mp4" }
}
```

Errors:
- `400` — bad `media_type` or extension not in whitelist.
- `401` — missing/invalid token.
- `502` — R2 round-trip failed.
- `503` — server is missing R2 credentials (check `.env`).

**Allowed extensions:**
- `image`: jpg, jpeg, png, webp, heic
- `audio`: m4a, mp3, aac, wav, ogg
- `video`: mp4, mov, webm

---

## 4. Flutter usage pattern

```dart
// 1. Ask backend for an upload URL
final res = await dio.post(
  '/api/v1/media/upload-url',
  data: {'media_type': 'audio', 'extension': 'm4a'},
);
final upload    = res.data;
final uploadUrl = upload['upload_url'] as String;
final publicUrl = upload['public_url'] as String;
final headers   = Map<String, String>.from(upload['required_headers']);

// 2. PUT the file straight to R2
final file  = File(localPath);
final bytes = await file.readAsBytes();
await Dio().put(
  uploadUrl,
  data: Stream.fromIterable([bytes]),
  options: Options(
    headers: {
      ...headers,
      'Content-Length': bytes.length.toString(),
    },
  ),
);

// 3. Persist the public URL on the diary entry
await dio.post('/api/v1/diary-entries', data: {
  'entry_type': 'audio',
  'body': '...',
  'media_items': [
    {
      'media_type': 'audio',
      'url': publicUrl,
      'duration_sec': 12.4,
      'language': 'pt',
    }
  ],
});
```

**Critical:** the `Content-Type` header on the PUT must exactly match the value
returned in `required_headers`. If it doesn't, R2 will reject the request with
`SignatureDoesNotMatch` because Content-Type is part of the signed request.

---

## 5. Operational notes

- **TTL.** Presigned URLs expire after `R2_PRESIGN_TTL_SEC` (default 15 min).
  If the user picks a file then takes a phone call before uploading, request a
  fresh URL.
- **Orphaned objects.** If the client uploads a file but never POSTs the diary
  entry (network drop, app crash), the object stays in R2. A periodic cleanup
  job that lists `diary/<user>/unbound/...` older than 24h and deletes objects
  with no matching `diary_media.url` row would tidy this up. Not needed for
  the demo.
- **Per-user bandwidth.** Direct uploads bypass the backend, so Render's free
  tier won't choke on 200 MB videos.
- **Deletion.** When a `diary_media` row is deleted (cascade from
  `diary_entries`), the object in R2 is *not* deleted automatically. Either
  add a cascade in the model layer (boto3 `delete_object` in a SQLAlchemy
  `before_delete` listener) or run a sweep job. Skip for v1 if storage is
  cheap; revisit when bucket grows.
- **Private/signed URLs.** If diary content turns out to be sensitive enough
  that public URLs are wrong, swap `build_public_url` for a presigned GET and
  generate a fresh GET URL on each diary-entry response. The bucket can stay
  private; only the upload code path changes.
