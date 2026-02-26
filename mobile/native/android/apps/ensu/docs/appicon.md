# Updating the Android app icon

This project uses an **adaptive icon** with a foreground PNG plus a solid background color.
The foreground must be padded so it fits inside circular/squircle masks without clipping.

## Sources
- **Foreground artwork**: provided by design (transparent PNG, 1024×1024).
- **Background color**: currently `#FDCE13` (see `res/values/colors.xml`).

## Steps

1. **Prepare the foreground**
   - Use the provided foreground PNG (transparent background).
   - Center the artwork on a square canvas and add **extra padding**.
   - Current safe-zone scale is **0.50** (content ~50% of canvas width).
   - This ensures the icon doesn’t clip in adaptive masks.

2. **Generate Android assets**
   - Adaptive foreground: `res/drawable/ic_launcher_foreground.png` (432×432).
   - Legacy icons (with background color):
     - `res/mipmap-mdpi/ic_launcher.png` (48×48)
     - `res/mipmap-hdpi/ic_launcher.png` (72×72)
     - `res/mipmap-xhdpi/ic_launcher.png` (96×96)
     - `res/mipmap-xxhdpi/ic_launcher.png` (144×144)
     - `res/mipmap-xxxhdpi/ic_launcher.png` (192×192)
   - Also update `ic_launcher_round.png` in each mipmap folder with the same image.

3. **Set the adaptive background color**
   - Update `res/values/colors.xml`:
     ```xml
     <color name="ic_launcher_background">#FDCE13</color>
     ```
   - Adaptive icon XMLs already reference this color:
     - `res/mipmap-anydpi-v26/ic_launcher.xml`
     - `res/mipmap-anydpi-v26/ic_launcher_round.xml`

4. **Verify**
   - Install on a device and check the icon under:
     - Circle mask
     - Squircle mask
     - Themed launcher

## Notes
- If the icon still clips in circular masks, reduce the foreground safe-zone scale (e.g., 0.45).
- Keep the artwork centered when adjusting padding.
