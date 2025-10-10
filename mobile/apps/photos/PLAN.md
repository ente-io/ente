**Title**
Fix Android Crop Mapping With Metadata Rotation (90°/270°) and User Rotation

**Date**
2025-10-07

**Owner**
photos/video-editor — Flutter client

**Objective**
- Make the exported crop match exactly the user’s on-screen crop box for all aspect ratios (1:1, 16:9, 3:4, free), whether or not the user applies an additional rotation, on Android videos that carry metadata rotation (90°/270°).

**Background (Current Behavior)**
- UI displays the video in the intended portrait/landscape by applying `RotatedBox(quarterTurns = metadataRotation/90)` and swaps preview dimensions.
- Crop box (minCrop/maxCrop) is chosen in the UI’s display space (after rotation correction).
- Native path (Android): for metadata 90°/270°, we compute a display-space `cropRect` and pass it directly to the native exporter, assuming the plugin transforms it. Logs show Media3 crops in file-space (pre-rotation), causing spatial mismatches, especially with user rotation.
- FFmpeg path: we already recompute a file-space `crop=` filter using a mapping util — more consistent.
- UI currently inverts aspect ratio when metadataRotation is odd (e.g., 16:9 → 9:16) to “match file space”. This conflicts with computing in display space.

**Observed Fail Modes (from findings.md and logs)**
- 1:1 on 90° clips: Dimensions correct (1080×1080) but content cropped from wrong region (top-left of file rather than top of portrait).
- 16:9 on 90° clips: Output `607×1080` instead of expected `1080×607` because aspect was inverted (preferredAspect=0.5625) and display dims were swapped.
- 3:4 across width + user cw rotation: Output ~1440×1080 (dimension ok after rotation) but content not from intended bounds due to crop being interpreted in plugin’s transformed space.

**Design Principles**
- Single source-of-truth coordinate system for the user interaction: UI display space.
- Always transform the user-selected display-space crop rectangle into file-space before export.
- Treat aspect ratios as width:height in the current display orientation (no inversion in the UI layer).
- Keep the native and FFmpeg paths consistent by reusing one mapping function.
- Enforce codec-friendly even dimensions and in-bounds clamping in file-space.

**Target Pipeline**
1) UI shows rotated preview (unchanged) and lets user pick crop in display space.
2) We compute a display-space rect that honors the chosen aspect ratio and clamping.
3) We map this display-space rect into file-space using a deterministic transform that accounts for metadataRotation and userRotation, with crop interpreted pre-rotation.
4) We pass only the mapped file-space rect to the exporter (native or FFmpeg), ensuring identical results between paths.

**Mapping Details**
- Inputs: `displayRect`, `videoSize` (file space W×H), `metadataRotation` (0/90/180/270), `userRotation` (0/90/180/270).
- For metadata 90°/270°: display is a rotated view of the file. Map each corner via the inverse rotation back into file-space, then take the bounding box; finally clamp and floor-even to avoid codec issues.
- User rotation handling:
  - Crop happens BEFORE user rotation in the pipeline. Compute and pass crop in original file space.
  - User rotation does not change crop coordinates; it only rotates the already-cropped output.
  - Examples:
    - 90° metadata, user rotation=0: 1:1 top square → file-space crop (x=0,y=0,w=1080,h=1080) → output 1080×1080.
    - 90° metadata, user rotation=90 cw: same file-space crop (0,0,1080,1080) → exporter rotates → output still 1080×1080, but visually rotated.
    - 90° metadata, user rotation=90 cw, 3:4 full-width top: file-space crop (0,0,1080,1440) → exporter rotates → final 1440×1080.

**Implementation Plan**
- lib/ui/tools/editor/video_crop_page.dart
  - Stop inverting aspect ratio for odd quarter-turns. Use aspect ratios as labeled (16:9=1.777…, 3:4=0.75, etc.).
  - Keep `RotatedBox` preview with `overrideWidth/Height` as is.

- lib/ui/tools/editor/crop_coordinate_mapper.dart
  - Promote to single mapping source: add `mapDisplayRectToFileRect({displayRect, videoSize, metadataRotation, userRotation})` which:
    - Applies inverse of `metadataRotation` to transform display-space points to file-space.
    - Ignores `userRotation` for mapping (crop is pre-rotation), but the function will accept it for clarity/logging.
    - Floors to even, clamps within file bounds, and returns `(x,y,width,height)`.
  - Add small helpers for 0/90/180/270 transforms.
  - Documentation: inline formulas for each rotation, why userRotation is ignored for mapping, and ASCII diagrams.

- lib/ui/tools/editor/native_video_export_service.dart
  - Replace the Android-rotated branch: compute display-space rect (same logic for aspect fit/center/clamp) using the UI-visible display dims (no swap), then call the mapper and pass file-space rect to `NativeVideoEditor.processVideo`.
  - Ensure event order: we pass `rotateDegrees = controller.rotation` and `cropRect = mappedFileRect` (file space). Do not pass display-space rects.
  - Maintain detailed logs: input min/max crop, aspect, display rect, mapped file rect.

- lib/ui/tools/editor/video_crop_util.dart
  - Refactor to delegate to the same mapper for FFmpeg (so both paths share the exact math). Keep `toFFmpegFilter()` builder.

**Testing & Validation**
- Manual matrix (run via tmux; verify both output dimensions and visual content):
  - Portrait (file 1920×1080, metadata=90), user rotation = 0:
    - 1:1 top square → expect 1080×1080; content is top of portrait.
    - 16:9 across width, top-anchored → expect 1080×607/608.
    - 3:4 across width, top-anchored → expect 1080×1440.
  - Portrait with user rotation = 90 cw:
    - Same three crops; dimensions rotated accordingly (w↔h), content matches rotated selection.
  - Portrait (file 1920×1080, metadata=270), user rotation = 0 and 90 cw:
    - Repeat 1:1, 16:9, 3:4, validate mirrored mapping.
  - Landscape (metadata=0):
    - 1:1, 16:9, 3:4 center/top-left crops match both content and dimensions.
  - Force FFmpeg path (internal toggle) and repeat one portrait scenario; verify identical result to native.
  - Free-form crops (no preset ratio), including very small selections and crops tight to each boundary (top/left/right/bottom), ensure anchors preserved and no out-of-bounds.

**Acceptance Criteria**
- For each scenario above, exported video region visually matches the selected crop box; dimensions match expectations (±1px rounding where half-odd rounding occurs).
- Logs contain both display-space and mapped file-space rects; Media3 “Crop: [x,y WxH]” equals the mapped file-space rect (modulo even rounding).
- FFmpeg and native outputs are indistinguishable for the same input crops.

**Error Recovery Strategy**
- If after even-number flooring the rect exceeds bounds (e.g., x+w>W), shift x/y inward to keep the rect fully inside while preserving any locked edge (e.g., if minY≈0 before rounding, keep top anchored).
- If mapped coordinates are degenerate (w≤0 or h≤0) or the native exporter rejects the rect, log and automatically fall back to FFmpeg export for that attempt.
- Surface a one-line toast to internal users indicating fallback.

**Visual Debugging**
- Add a dev-only overlay (behind internal flag) in the editor preview showing:
  - Green: display-space crop rect.
  - Red: mapped file-space rect reprojected to display space for comparison.
- Toggle via a debug action in the editor or a gesture to verify mapping visually during QA.

**Performance Considerations**
- Mapping is O(1) (4 points × matrix-lite ops); negligible cost.
- Cache the last computed mapping per controller state; recompute only on crop change end or when aspect changes (throttle during drag to keep UI smooth).
- Log construction should be gated behind internal flag to avoid string work in release.

**Documentation Improvements**
- In `crop_coordinate_mapper.dart`, add detailed docstrings:
  - Mathematical transformation for 0/90/180/270 (with axis swaps and origin handling).
  - Rationale for ignoring user rotation in mapping (crop-before-rotate pipeline).
  - ASCII diagrams for metadata=90 and 270 showing corners mapping.

**Backwards Compatibility**
- Keep `editor.useFileSpaceCropMapping` feature flag.
- If there are cached/persisted crop settings (min/maxCrop) captured under legacy logic, detect when loading an old draft and re-map them to display space before use; log a one-time migration notice for internal users.
- Detect plugin/Media3 version at runtime (if exposed) and log it with export to aid future compatibility investigations.

**Activation Strategy & Observability**
- Always ON for Android when metadataRotation is 90° or 270° (the broken cases). No runtime feature flag.
- Keep INFO logs in native and FFmpeg paths for: metadataRotation, userRotation, min/max crop, preferred aspect, display dims, display rect, mapped file rect, and final command/effects. Gate extra-verbose logs behind `flagService.internalUser`.

**Compatibility Notes**
- If there are cached/persisted crop settings (min/maxCrop) captured under legacy logic, detect on load and re-map to display space before use (log one-time migration for internal users).
- Detect plugin/Media3 version at runtime (if exposed) and log it with export to aid future compatibility investigations.

**Risks & Mitigations**
- Risk: Subtle off-by-one or even-pixel constraints causing FFmpeg/MediaCodec errors.
  - Mitigation: floor-even widths/heights, clamp x/y to stay in-bounds post-rounding.
- Risk: UI aspect selection behavior change when removing inversion.
  - Mitigation: keep visual grid stable; verify that selecting “16:9” shows a wide rect in portrait, consistent with user expectation.

**Out-of-Scope**
- iOS-specific crop mapping changes (current logic appears consistent; revisit if similar symptoms are reported).

**Timeline (engineering days)**
- Day 1: Implement mapper, refactor native and FFmpeg paths, remove UI inversion, add logs.
- Day 2: Validate matrix on multiple samples; fix edge cases; prepare PR with findings and before/after captures.
