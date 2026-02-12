# Ente Screensaver (Android TV)

A lightweight Android TV screensaver that plays photos from an Ente public album.

## Features
- Ente public albums, including password‑protected albums.
- QR + LAN setup flow with pairing code (server runs only on the Setup screen).
- Full‑image downloads (not thumbnails), with on‑device caching.
- Video files are skipped; unsupported images are transcoded to JPEG when possible.
- Configurable cache size and refresh interval.
- Diagnostics page with recent logs and status helpers.

## Quick Start (TV)
1. Install the release APK from `app/build/outputs/apk/release/app-release.apk`.
2. Open the app and select **Step 1: Connect album** to scan the QR or paste your public album link.
3. Select **Step 2: Set as screensaver** and tap **Set as screensaver**.
4. If the TV blocks changes, open **ADB instructions** and run:

   ```
   adb shell pm grant io.ente.photos.screensaver android.permission.WRITE_SECURE_SETTINGS
   ```

   Then tap **Set as screensaver** again.
5. Open **Settings → Preview** to confirm the slideshow is working.

## Settings
- **Slideshow interval** (default: 5 minutes)
- **Ente cache size** (default: 15 photos)
- **Ente refresh interval** (default: 1 hour)
- **Fit mode**, **Shuffle**, **Clock**

## Setup Notes
- Your phone must be on the same Wi‑Fi network as the TV to use QR setup.
- The setup page is available only while the Setup screen is open.

## Troubleshooting
- Open **Diagnostics** to view recent logs and device status.
- If photos fail to load, verify:
  - The public URL contains an access token (`?t=...` or `/<token>`) and a `#...` collection key fragment.
  - The album password (if any) is correct.
  - The TV has network access to `api.ente.io` and `public-albums.ente.io`.

## Release Build
Run:
```
./gradlew assembleRelease
```
Output:
`app/build/outputs/apk/release/app-release.apk`

## More Docs
- `docs/SETUP.md` — detailed setup steps
- `docs/RELEASE.md` — release checklist
- `docs/TRANSLATIONS.md` — Crowdin localization workflow
