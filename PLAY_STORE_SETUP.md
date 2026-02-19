# Google Play Store Setup

## Manual Steps Required (One-Time)

The CI workflow is ready. Before the first automatic upload works, you need to:

### 1. Grant service account access in Play Console
1. Go to https://play.google.com/console
2. Setup → API access → Link to Google Cloud project
3. Find service account: `play-upload@live-captions-xr.iam.gserviceaccount.com`
4. Grant "Release manager" permission
5. Click "Apply permission changes"

### 2. Create initial release manually
The service account can only upload to an existing app listing.
If this is the first upload, you must create the first release manually via:
- Play Console → LiveCaptionsXR → Internal testing → Create new release
- Upload any valid `.aab` file to create the listing
- After that, CI can upload automatically

### 3. Add keystore secrets (for signed builds)
In GitHub repo Settings → Secrets → Actions:
- `KEYSTORE_BASE64` — base64-encoded `.jks` keystore file (`base64 -w0 upload-keystore.jks`)
- `KEYSTORE_PASSWORD` — keystore password
- `KEY_PASSWORD` — key password
- `KEY_ALIAS` — key alias

`GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` is already set ✅

### 4. Trigger a release
After setup, trigger the workflow:
- **Tag-based:** `git tag v1.0.44 && git push origin v1.0.44`
- **Manual:** Actions → Deploy to Google Play → Run workflow (choose track)

## CI/CD Flow

```
v* tag push → [parallel]
  ├── CI (tests)
  ├── Release (GitHub Release + APK + Cloudflare Pages)
  └── Deploy to Google Play (AAB → internal track as draft)
```

## Notes
- The workflow defaults to **internal** track with **draft** status (safe — won't go live automatically)
- Promote from internal → alpha → beta → production manually in Play Console
- Package name: `com.livecaptionsxr.app`
- Service account: `play-upload@live-captions-xr.iam.gserviceaccount.com`
