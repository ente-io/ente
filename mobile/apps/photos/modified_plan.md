**Title**
Modified Plan: Android Crop Mapping (Rotated Metadata)

**Context**
Great write‑up—you’ve isolated the right root causes and the high‑level plan is solid: build the crop in display space, map it once to file space using the correct inverse‑rotation math, and keep user rotation separate (crop‑first, then rotate). Below are fixes and a tightened, implementation‑ready spec.

**Keep (Correct Items)**
- One math path shared by Media3 and FFmpeg.
- Display‑first thinking: aspect ratio is width:height in the UI orientation (don’t invert to 9:16 for portrait).
- Anchors (top/left/right/bottom) enforced while building the display rect.
- Inverse‑rotation mapping from display → file for 0/90/180/270.
- Crop‑before‑rotate (user rotation does not change crop coordinates).
- Even rounding of output dimensions with predictable clamping.

**Corrections / Gaps To Address**
1) Concrete example dimensions (two swaps)
   - For metadata=90°, your examples swapped width/height in file space.
   - 16:9 across the top width (portrait 1080×1920, file 1920×1080):
     - File‑space crop should be a left strip ≈ 607/608 × 1080 (w small, h large), not 1080 × 607/608.
     - Correct file rect: (x=0, y=0, w≈607/608, h=1080). After post‑crop metadata rotation, final is 1080×607/608.
   - 3:4 across full width + user clockwise rotation:
     - File‑space crop should be 1440 × 1080, not 1080 × 1440.
     - Correct file rect: (x=0, y=0, w=1440, h=1080). After metadata rotation (90°): 1080×1440, then user CW 90°: 1440×1080.
   - Intuition: with metadata=90°, UI “top” maps to file left, and UI width maps to file height. Top bands in display become left strips in file.

2) Make the “metadata rotation” step explicit (post‑crop)
   - Export pipeline must physically rotate pixels by the file’s metadata after cropping (normalize orientation) before applying any user rotation. Media3 may log this as a ScaleAndRotateTransformation.
   - Required order:
     1. Crop using the mapped file‑space rect.
     2. Rotate by metadataRotation (normalize orientation).
     3. Rotate by userRotation (if any).
     4. Scale/encode.

3) Snap x, y to the chroma grid (not just w, h)
   - For YUV 4:2:0 (typical on Android), x, y, w, h must be even.
   - For 4:2:2: x, w even.
   - For 4:4:4: no constraint.
   - Prefer to keep anchored edges fixed and move the opposite edge to satisfy alignment.

4) Use the content viewport, not the view size
   - `displaySize` must be the actual video content rectangle inside the preview after rotation correction (exclude letterboxing/pillarboxing). Normalize min/maxCrop relative to that content rect.

5) Minor nits
   - In “Step 1”, the correct raw rect is: `raw = LTRB(min.x * displayW, min.y * displayH, max.x * displayW, max.y * displayH)`.
   - In mapping formulas, keep explicit multiplies for readability (e.g., `xf = ndx * Wf`).

**Implementation‑Ready Spec**

- Activation: Always ON for Android when `metadataRotation ∈ {90,270}`. No feature flag. iOS and 0°/180° follow the same unified code path where applicable.

- Inputs
  - `displayW, displayH`: content preview size after rotation correction (e.g., 1080×1920).
  - `fileW, fileH`: encoded frame size (e.g., 1920×1080).
  - `minCrop, maxCrop ∈ [0,1]` display‑normalized (sort if out of order).
  - `preferredAspect` (width:height in display space) or null.
  - `metadataRotation ∈ {0,90,180,270}` (clockwise degrees).
  - `userRotation ∈ {0,90,180,270}` (clockwise, relative to UI preview).
  - `pixelFormat` (e.g., yuv420p) to set grid constraints.

- Step 1 — Build the enforced display rect (with anchors)
  - `raw = LTRB(min.x * displayW, min.y * displayH, max.x * displayW, max.y * displayH)`; normalize L/T/R/B ordering.
  - Detect anchors with ε≈0.02 on normalized min/max: top, bottom, left, right.
  - If `preferredAspect != null`, let `targetAR = preferredAspect` (w:h in display space), then enforce while preserving anchors:
    - Left+Right locked → `w = displayW`, `h = w / targetAR`; vertically center inside `raw` unless top or bottom also locked.
    - Top+Bottom locked → `h = displayH`, `w = h * targetAR`; horizontally center unless left or right is locked.
    - Top only → `h = min(raw.h, raw.w / targetAR)`; keep top; horizontally center within `raw`.
    - Left only → `w = min(raw.w, raw.h * targetAR)`; keep left; vertically center within `raw`.
    - None → center‑fit `targetAR` inside `raw`.
  - Clamp final display rect to `[0..displayW] × [0..displayH]`.

- Step 2 — Map display → file via inverse metadata rotation
  - Normalize corners: `ndx = x / displayW`, `ndy = y / displayH`.
  - For each corner, map to file space (`Wf=fileW`, `Hf=fileH`):
    - rot 0:   `xf = ndx * Wf`;         `yf = ndy * Hf`
    - rot 90:  `xf = ndy * Wf`;         `yf = (1 - ndx) * Hf`
    - rot 180: `xf = (1 - ndx) * Wf`;   `yf = (1 - ndy) * Hf`
    - rot 270: `xf = (1 - ndy) * Wf`;   `yf = ndx * Hf`
  - Take the AABB of the 4 mapped points → `(x, y, w, h)` in file space.
  - Note (odd rotations): UI top ↔ file left (90°), UI top ↔ file right (270°). Thus top bands in display map to left/right strips in file.

- Step 3 — Grid / rounding / clamping with anchors
  - Clamp: `x ≥ 0`, `y ≥ 0`, `x+w ≤ fileW`, `y+h ≤ fileH`.
  - Chroma grid: apply subsampling constraints by pixelFormat.
    - 4:2:0 → even `x, y, w, h`.
    - 4:2:2 → even `x, w`.
    - 4:4:4 → no constraint.
  - Rounding policy: nearest‑even (or toward‑inside) for `w, h`; snap `x, y` to grid while preserving locked edges; if OOB after rounding, slide the non‑anchored side inward minimally.
  - Ensure `w, h ≥ 2` and rect remains inside bounds.

- Step 4 — Export transform order
  1. Crop to `(x, y, w, h)` in file space.
  2. Rotate by `metadataRotation` to normalize orientation.
  3. Rotate by `userRotation` (UI intent), i.e., `total = (metadataRotation + userRotation) mod 360` (apply as two steps if Media3 requires).
  4. Scale/encode.

**Corrected Concrete Examples**
- 1:1 top square (file 1920×1080, metadata=90)
  - Display: `(0,0,1080,1080)`
  - File (inverse 90): `(0,0,1080,1080)` ← left square
  - Rotations: `+90` (metadata) ⇒ square; user=0 ⇒ final `1080×1080`.

- 16:9 across top width
  - Display: `w=1080`, `h≈607.5` ⇒ even → `608`.
  - File: `(x=0, y=0, w≈608, h=1080)` (left strip).
  - Rotations: `+90` ⇒ final `1080×608`.

- 3:4 across width + user CW
  - Display: `w=1080` ⇒ `h=1440`.
  - File: `(x=0, y=0, w=1440, h=1080)`.
  - Rotations: `+90` ⇒ `1080×1440`; `+90` (user) ⇒ `1440×1080`.

**Quick Implementation Hints**
- For odd rotations, remap anchors for rounding: 90° (top↔left, bottom↔right), 270° (top↔right, bottom↔left).
- Always sort min/max first; detect anchors using ε on normalized inputs.
- Use the content viewport size from the video widget (post‑rotation) as `displayW/H`.
- Unit test by forward‑mapping display→file and validating Media3 “Crop: [x,y W×H]” matches; test small and edge‑anchored crops too.
- Ensure Media3’s operation order matches crop‑then‑rotate; if not, pre‑adjust the file rect into the space Media3 crops in.

**Bottom Line**
Fix the swapped examples, explicitly apply metadata rotation after crop, align `x,y` to chroma grids, and use the content viewport. With an enforced display rect (aspect + anchors) and correct inverse‑rotation mapping, both Media3 and FFmpeg will produce identical, predictable crops that match the on‑screen selection.

