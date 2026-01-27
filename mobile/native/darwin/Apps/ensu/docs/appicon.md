# Updating the iOS app icon

The iOS app icon uses a 1024×1024 foreground image centered on a square canvas.
**Do not add extra padding or scaling**—use the foreground artwork as-is.

## Sources
- **Foreground artwork**: provided by design (transparent PNG, 1024×1024).
- **Backgrounds**:
  - Any (default): `#FFEEDD`
  - Dark: **transparent** (so the system dark gradient can show)
  - Tinted: **white** (so tinting behaves correctly)

## Assets to update
Update the files inside:
```
mobile/native/darwin/Apps/ensu/ensu/Assets.xcassets/AppIcon.appiconset
```

Required files:
- `IconOGAny.png` (foreground on #FFEEDD)
- `IconOGDark.png` (foreground on transparent background)
- `IconOGTinted.png` (foreground on white background)

## Steps
1. Open the provided foreground PNG and keep it at **1024×1024**.
2. Center the foreground on a 1024×1024 canvas.
3. Export three variants:
   - **Any**: background `#FFEEDD`
   - **Dark**: transparent background
   - **Tinted**: background `#FFFFFF`
4. Replace the corresponding files in `AppIcon.appiconset`.
5. Rebuild the app in Xcode to refresh the asset catalog.

## Notes
- Do **not** add extra padding for iOS; the foreground sizing is already correct.
- If the artwork is delivered at a different size, scale it to **1024×1024** first and keep it centered.
