Title
Crop Mapping v3 — General-Purpose Fix Across Native (Media3) and FFmpeg

Context
- After unifying display→file mapping, output dimensions are correct. Remaining issues:
  - Native (Media3): preset ratios (e.g., centered 1:1) sometimes look “zoomed” (content exceeds intended selection). Free crop tends to look correct.
  - FFmpeg: some centered crops start at top-left despite correct size (origin drift after rounding/rotation).
- Goal: a general solution that behaves predictably for all ratios, rotations, and pixel formats.

Observed Symptoms (Generalized)
- Preset 1:1, 16:9, 3:4 crops show correct size but:
  - Native: content looks expanded (cover-fit), not the user’s contained selection.
  - FFmpeg: result is offset to top-left for centered crops.

Likely Root Causes
1) Aspect enforcement policy mismatch (contain vs cover): preset ratios expanded to full viewport rather than constrained to the user’s envelope/center.
2) Undefined anchors when no edges touch: center lost during rounding/clamping → top/left bias (FFmpeg).
3) Chroma-grid alignment without center preservation: snapping x/y/w/h to 4:2:0 grid shifts rect off-center.
4) Transform-order mismatch between pipelines: crop/rotate/scale order differs between native and FFmpeg if not normalized.
5) Using widget size instead of content viewport for min/max normalization.

General-Purpose Solutions
S1) Aspect enforcement policy with explicit contain/cover behavior
   - Preset ratios: CONTAIN within the user’s current selection envelope; expand to full viewport only if both edges on that axis are explicitly locked.
   - Free crop: honor user bounds without forced aspect.

S2) Explicit anchoring (with center default)
   - Per axis, lock left/right or top/bottom if min≈0/max≈1 (ε≈0.02). If neither side is locked, treat as center-anchored.

S3) Center-preserving chroma alignment (inside-only)
   - Record rect center pre-alignment. Use grid from pixelFormat (e.g., yuv420 → step=2).
   - Never enlarge: w' = floor_to_step(w), h' = floor_to_step(h).
   - Anchors: keep locked sides fixed; adjust the opposite edge using w'/h'. If center-anchored, place x = round_to_step(cx − w'/2), y = round_to_step(cy − h'/2).
   - Clamp x ∈ [0..Wf−w'], y ∈ [0..Hf−h']; for center-anchored axes, slide symmetrically if clamped; if impossible, accept asymmetry but do not grow w'/h'.
   - Enforce minimums: w' ≥ stepW, h' ≥ stepH; if bounds still violated, shrink (never expand).

S4) Normalize transform order across pipelines
   - Export: CROP (file space) → ROTATE by metadata → ROTATE by user → SCALE/encode.
   - FFmpeg: `-noautorotate -vf "crop=w:h:x:y[,transpose=.. for metadata][,transpose=.. for user]" -pix_fmt yuv420p -vsync 1 -movflags +faststart`.
   - Media3: ensure added Effects chain implements crop before rotate; if not possible, pre-transform rect to the space Media3 crops in.

S5) Use content viewport exclusively
   - Compute displayW/H from the video content rect after rotation correction and letterboxing removal. Normalize min/max to that rect.

Architecture & APIs
- DisplayRectBuilder (lib/ui/tools/editor/display_crop_rect_builder.dart)
  - Input: `displaySize, minCrop, maxCrop, preferredAspectRatio`.
  - Output: `DisplayCropRect { Rect rect; bool lockTop/Bottom/Left/Right; }`.
  - Behavior: detect anchors, apply CONTAIN aspect policy, center-anchored by default when no locks.

- CropCoordinateMapper (lib/ui/tools/editor/crop_coordinate_mapper.dart)
  - Input: `DisplayCropRect, displaySize, fileSize, metadataRotation, pixelFormat`.
  - Output: `CropCoordinateMapperResult { Rect fileRect, Rect displayRect }`.
  - Behavior: inverse-rotate display→file per 0/90/180/270; align to chroma grid preserving center/anchors; clamp within file.

- Helper: Anchor remap
  - Provide a first-class helper used before grid alignment so rounding/snapping knows the true file-space locks.

```
FileAnchors remapAnchorsFromDisplay(DisplayAnchors anchors, int metadataRotation);
// For 90°: top→left, bottom→right, left→bottom, right→top; etc.
```

Viewport Determination
- If using `CropGridViewer` with `overrideWidth/Height`, the content viewport equals those values; otherwise compute from layout:
  - Let `videoW/H = controller.video.value.size` and `boxW/H = layoutSize`.
  - Fit modes: `scale = min(boxW/videoW, boxH/videoH)`, `contentW = videoW*scale`, `contentH = videoH*scale`.
  - Content origin in widget: `ox = (boxW - contentW)/2`, `oy = (boxH - contentH)/2`.
  - Normalize min/max against content rect, not `boxW/H`.

Detailed Algorithms
1) Aspect enforcement (CONTAIN)
   - raw = LTRB(min.x*displayW, min.y*displayH, max.x*displayW, max.y*displayH), normalized.
   - Detect locks: left=min.x≈0, right=max.x≈1, top=min.y≈0, bottom=max.y≈1.
   - If preferredAspect null → return raw.
   - targetAR = preferredAspect (w/h in display orientation).
   - If both edges locked on an axis: may expand on that axis; else enforce inside raw by shrinking the other dimension; if no locks on axis → center within raw.
   - Clamp to display bounds.

2) Inverse-rotation mapping (display→file)
   - Normalize corners: `ndx=x/displayW`, `ndy=y/displayH`.
   - Map to file (Wf=fileW, Hf=fileH):
     - rot 0:   xf=ndx*Wf;         yf=ndy*Hf
     - rot 90:  xf=ndy*Wf;         yf=(1-ndx)*Hf
     - rot 180: xf=(1-ndx)*Wf;     yf=(1-ndy)*Hf
     - rot 270: xf=(1-ndy)*Wf;     yf=ndx*Hf
   - AABB of 4 mapped points → (x,y,w,h) file rect.

3) Chroma-grid alignment with center preservation (inside-only)
   - Choose grid by pixelFormat: yuv420 → stepX,Y,W,H=2; yuv422 → stepX,W=2; yuv444 → steps=1.
   - Remap anchors to file space first:
     `FileAnchors fileAnchors = remapAnchorsFromDisplay(displayAnchors, metadataRotation);`
   - Record center (cx,cy) before alignment for center-anchored axes.
   - widths/heights: `w' = floor_to_step(w)`, `h' = floor_to_step(h)`; do not enlarge.
   - Anchors (inside-only policy):
     - Left locked: keep `x` fixed; set `right = x + w'`.
     - Right locked: keep `right` fixed; set `x = right − w'`.
     - Top locked: keep `y` fixed; set `bottom = y + h'`.
     - Bottom locked: keep `bottom` fixed; set `y = bottom − h'`.
     - Center-anchored: `x = round_to_step(cx − w'/2)`, `y = round_to_step(cy − h'/2)`.
   - Clamp: x∈[0..Wf−w'], y∈[0..Hf−h']; slide symmetrically when center-anchored; shrink if necessary; never grow.
   
4) Transform order in export
   - FFmpeg filter chain — non‑interpolating ops for 90/180/270:
     - metadataRot ops:
       - 90° CW: `transpose=1`
       - 90° CCW: `transpose=2`
       - 180°: `hflip,vflip` (prefer over two transposes)
     - userRot: apply the same mapping after metadata.
     - Full example: `-noautorotate -vf "crop=w:h:x:y,transpose=1,hflip,vflip" -pix_fmt yuv420p -vsync 1 -movflags +faststart[,setsar=1]`
   - Media3: configure `EditedMediaItem` with crop first, then rotation transform; ensure no extra scaling is introduced (or set output to `w×h` of rotated crop).
   - Invariant (native): resolvedOutputW,H must equal `applyRotations(fileRect.w,h, metadataRot+userRot)`; log both requested and resolved sizes.

Anchor Remapping (apply before alignment) and Mapping Table (display→file)
- 0°: same (top→top, left→left, ...)
- 90°: top→left, bottom→right, left→bottom, right→top
- 180°: top↔bottom, left↔right
- 270°: top→right, bottom→left, left→top, right→bottom

Apply this remapping before grid alignment so the alignment step knows which file-space edges are truly locked.

Integer-Ratio Aspects (kill float drift)
- Represent `preferredAspectRatio` as an integer pair `(aw:int, ah:int)` in display space.
- Use cross-multiplication for all comparisons: e.g., `w * ah ? h * aw`.
- Only convert to float at the end for logging; avoid 1‑px drift from 1.777… in odd rotations.

Contain vs Cover — explicit conditions
```
if preferredAspect != null:
  if axisHasBothEdgesLocked(axis):
     // COVER along this axis: expand to the full display along axis if it increases area
     // but never exceed display bounds.
  else:
     // CONTAIN: fit inside raw; never grow beyond raw on either axis.
```

Viewport correctness — assert
- Assertion: `(contentW,contentH)` must match the renderer’s source rect size for the preview (≤1 px tolerance). If mismatch, log dev warning with `boxW/H, videoW/H, scale, ox/oy`.
- Normalize `min/max` after subtracting `(ox,oy)` and dividing by `(contentW,contentH)`.

Pathological inputs
- Sort inputs so `min ≤ max` per axis; clamp to `[0,1]`.
- Ignore degenerate selections with area < `1/(displayW*displayH)` by snapping to a minimal rect centered at the selection center.
- Use two epsilons: `ε_anchor≈0.02` for lock detection, and `ε_merge≈0.001` to avoid flicker near edges while dragging.

Logging (structured, single-line)
- input: `rotation=<metadata>, user=<user>, disp=<W×H>, file=<W×H>, min=<dx,dy>, max=<dx,dy>, aspect=<>, raw=<LTRB>`
- enforced: `dispRect=<LTRB>, locks=<T/B/L/R>, centerAnchors=<X/Y>`
- mapped: `fileRect=<x,y,w,h>, grid=<format>, deltas=<xΔ,yΔ,wΔ,hΔ>`
- media: `Media3(Crop=<x,y,w,h>, Rotate=<deg>)` or `FFmpeg(vf="...")`
 - policy: `contain|cover` per axis, ops: `ffmpeg:<filtergraph>` / `media3:<effects>`
 - iou (test/QA builds): IoU of back‑projected file rect vs enforced display rect (target ≥ 0.99)

Test Matrix (must pass visually + numerically)
- Rotations: metadata {0,90,180,270} × user {0,90,180,270}.
- Ratios: free, 1:1, 16:9, 9:16, 3:4, 4:3.
- Anchors: top/bottom/left/right locked; fully centered (no locks).
- Edge/tiny crops: 2×2 min; near boundaries; letterboxed previews.
- Pixel formats: yuv420 (default), yuv422, yuv444 (simulated).
- Parity: native vs FFmpeg should yield identical crops (within 1px/rounding).

Invariants (machine‑checkable)
- Monotonicity: shrinking the selection in display space must not increase fileRect area.
- Parity: decode one exported frame and reproject fileRect back to display; IoU ≥ 0.99 with enforced displayRect.
- Anchor preservation: when top is locked in display and metadata=90°, the fileRect’s left coordinate must lie exactly on the grid (0‑tolerance after snapping).

Rollout
- Apply for Android rotated metadata (90/270) unconditionally; share code path elsewhere where safe. Keep enhanced logs for internal validation, then reduce.

Risks / Mitigations
- 1px drift from rounding → re-center when unanchored; keep locked side fixed.
- Media3 implicit scale/rotate order → confirm via logs; if mismatch, pre-transform rect into Media3’s crop space or adjust effects order.
- Viewport detection errors → assert on sizes; add dev warning if `overrideWidth/Height` mismatch underlying video aspect.

FFmpeg top-left drift (explicit note)
- Center-anchored default + anchor remap + re-centering after grid snap removes the top/left bias.
- Using non‑interpolating rotate ops (transpose=1/2 for 90°, hflip,vflip for 180°) preserves exact pixel centers.

Conclusion
- With these redlines incorporated verbatim, v3 should produce visually identical, numerically stable crops across Media3 and FFmpeg for all preset ratios, metadata/user rotations at 0/90/180/270, and YUV pixel formats 4:2:0 / 4:2:2 / 4:4:4.
