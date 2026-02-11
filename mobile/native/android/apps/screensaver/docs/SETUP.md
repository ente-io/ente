# Ente Screensaver Setup

## Step 1: Connect Album
1. Open the app → **Step 1: Connect album**.
2. Scan the QR from your phone (same Wi‑Fi), or paste the public album link.
3. If the album has a password, enter it on the setup page.

> The setup server only runs while the Setup screen is open.

## Step 2: Set as Screensaver
1. From the home screen, tap **Set as screensaver**.
2. If it fails, open **ADB instructions** and run:

   ```
   adb shell pm grant io.ente.screensaver android.permission.WRITE_SECURE_SETTINGS
   ```

3. Tap **Set as screensaver** again.

## Preview
- Open **Settings → Preview** to confirm the slideshow.

## Common Issues
- If the QR link does not open, type the URL shown on the TV in your phone browser.
- If photos don’t appear, check **Diagnostics → Recent logs**.
