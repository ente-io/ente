**Title**
Android Crop Mapping Findings (90°/270° metadata rotation)

**Date**
2025-10-07

**Branch/Scope**
`video-editor-revamped` — Flutter client (Video Editor)

**Summary**
- Source video recorded in portrait: expected display 1080×1920, file stored as 1920×1080 with metadata rotation=90°.
- User cropped a top square (from top-left to top-right), expecting output to be the top 1080×1080 region of the portrait.
- Output dimensions were correct (1080×1080), but the content was not the top square the user selected.

---

**Scenario 2 (User-applied clockwise rotation)**

**Expectation**
- User applies a clockwise rotation in the editor and keeps a 1:1 crop.
- The 1:1 crop box, now visually rotated, should still select the intended region (the rotated top square) and export as 1080×1080 with matching content.

**Reality (Observed)**
- Dimensions are still 1080×1080 (correct), but the final content does not match the rotated crop box and appears zoomed/misaligned.

**Evidence (grep from /tmp/flutter-photos-video-editor.log)**
- `[VideoEditor] … Video info: 1920x1080, rotation=90` and `Applying rotation correction: 90° → 1 quarter turns`.
- `[NativeVideoExportService] Android rotated crop input: rotation=90 (1 quarter turns) … minCrop=Offset(0.0, 0.0), maxCrop=Offset(0.6, 1.0), preferredAspect=1.0`.
- `[NativeVideoExportService] Android rotated crop rect display-space: left=0.00, top=0.00, width=1080.00, height=1080.00`.
- `Media3Transformer: Rotate: 270 degrees` (user’s clockwise rotation), and `Crop: [0,0 1080x1080]`.
- `Media3Transformer: Original video: 1920x1080, rotation=90` and `Adding rotation effect: 270 degrees … Added ScaleAndRotateTransformation …`.

**Interpretation**
- The pipeline shows a rotation effect (270° cw) alongside a crop at `[0,0 1080x1080]`.
- Although `[0,0 1080x1080]` can be correct for certain mappings, the plugin likely applies `ScaleAndRotateTransformation` in a way that changes the coordinate space (rotation+scale) relative to our display-space selection, causing the visual mismatch/zoom.
- In short, the native path still lacks a deterministic display→file mapping when a user rotation is introduced on top of metadata rotation.

**Actionable Update**
- Extend the mapping to consider both metadata and user rotation when generating the file-space crop rectangle used by the native path. Do not rely on the plugin to reconcile crop with scale+rotate; pre-map explicitly and pass the mapped file-space rect.

---

**Scenario 3 (16:9 crop on portrait video, no user rotation)**

**Expectation**
- Displayed portrait is 1080×1920; selecting a 16:9 crop across the top should keep full width and set height to `1080 × 9/16 = 607.5` → output roughly `1080×608`.
- Crop box: left-to-right width=1080, top-to-bottom height≈608 (anchored at top).

**Reality (Observed)**
- Native export logs show:
  - `[VideoEditor] … rotation=90 → 1 quarter turns`.
  - `[NativeVideoExportService] … minCrop=Offset(0.0, 0.0), maxCrop=Offset(0.3, 1.0), preferredAspect=0.5625`.
  - `[NativeVideoExportService] … displaySize=1920.00x1080.00, … crop rect display-space: left=0.00, top=0.00, width=607.50, height=1080.00`.
  - `Media3Transformer: Rotate: none degrees` and `Crop: [0,0 607x1080]`.
- Resulting output dimension observed: `608×1080` (width≈607–608, height 1080) — which is the inverse of the expected `1080×608`.

**Interpretation**
- Two issues compound:
  1) The aspect ratio used is `0.5625` (9/16). For a “16:9” selection expressed as width/height, we should be using `16/9 ≈ 1.777…` in the display space. The UI currently inverts ratios under metadata 90°/270° (see VideoCropPage), which is correct only if subsequent math is done in the unrotated file space. Our Android native path computes in display space, so the inversion is inappropriate here.
  2) The Android-rotated branch in `NativeVideoExportService` sets `displayWidth=videoSize.height` and `displayHeight=videoSize.width`, yielding `displaySize=1920×1080` while the user-visible portrait area is effectively 1080×1920. This swap misidentifies which dimension is “width” in display space, and combined with the inverted aspect leads to a `[607×1080]` crop instead of `[1080×607]`.

**Conclusion**
- For Android with metadata rotation=90°/270° and no user rotation:
  - Do not invert the 16:9 ratio to 9:16 for display-space math; keep it as `16/9`.
  - Treat display dimensions as the UI-visible orientation (`displayWidth=video.value.size.width`, `displayHeight=video.value.size.height`) instead of swapping them.
  - After computing the display-space rect, map to file-space before invoking the native exporter.

**Next Steps**
- Update `VideoCropPage` to stop inverting `preferredCropAspectRatio` on Android when we intend to perform display-space-native export.
- In `NativeVideoExportService` (Android rotated branch): use UI display dims (no swap), interpret `preferredCropAspectRatio` as width/height, and then map to file-space via the mapper before calling the plugin.
- Re-test 1:1 and 16:9 top-row crops; confirm Media3 logs show the expected `Crop: [x,y w×h]` and validate the visual output matches the selection.

---

**Scenario 4 (3:4 crop from top-left across width, then 90° clockwise rotation)**

**Expectation**
- Portrait display 1080×1920. A 3:4 crop covering full width results in a 1080×1440 region at the top-left. Applying an additional 90° clockwise rotation yields a final 1440×1080 output. The content should match the exact top-left 3:4 area selected in the UI.

**Reality (Observed)**
- Logs:
  - `[VideoEditor] … rotation=90 → 1 quarter turns`.
  - `[NativeVideoExportService] … minCrop=Offset(0.0, 0.0), maxCrop=Offset(0.7, 1.0), preferredAspect=1.3333333333333333`.
  - `Media3Transformer: Rotate: 270 degrees; Crop: [0,0 1439x1079]`.
- Output dimension: ~1440×1080 (matches the rotated 3:4 expectation), but the visual content does not match the intended top-left 3:4 region (bounds appear offset/incorrect).

**Interpretation**
- The UI inverts the 3:4 ratio to 4:3 (preferredAspect≈1.333) because the clip has metadata rotation=90°. This is consistent with the earlier inversion behavior and with using a 1920×1080 display space in the editor.
- With user rotation (270° cw) also applied, the plugin applies `ScaleAndRotateTransformation` and then crops using `[0,0 1439x1079]`. The crop appears to be interpreted in the plugin’s transformed space, not in the original file space that corresponds to the on-screen selection, yielding a spatial mismatch even though final dimensions are as expected.

**Conclusion**
- The same root cause persists when user rotation is combined with the 3:4 crop: we’re not pre-mapping the on-screen selection to the correct file-space region that the native pipeline will crop after its internal rotate/scale. Dimensions end up correct due to aspect enforcement, but content does not align with the selected area.

**Action Items (reiterated for this case)**
- Do not invert aspect ratios for Android 90°/270° when working in the editor’s display space; keep ratios as-labeled (3:4 → 0.75, 16:9 → 1.777…).
- Compute the crop in the editor’s display space (consistent with the `CropGridViewer` override sizing), then deterministically map that rect into file-space while accounting for both metadata and user-applied rotations.
- Pass only file-space crop rectangles to the native exporter so Media3 performs the correct spatial crop irrespective of its internal transform order.

**Expectation**
- Crop area in portrait display space: from (0,0) to (1080,1080) — i.e., the topmost square of the portrait.
- Exported video shows exactly that region; no additional rotation applied by user.

**Reality (Observed)**
- Dimensions: 1080×1080 (as expected).
- Content: not the top square from the portrait; appears offset/misaligned, consistent with a crop taken from the file’s un-rotated (landscape) coordinate system.

**Key Logs (from /tmp/flutter-photos-video-editor.log)**
- `[VideoEditor] … Video info: 1920x1080, rotation=90` and `Applying rotation correction: 90° → 1 quarter turns`.
- `[NativeVideoExportService] Android rotated crop input: rotation=90 (1 quarter turns), videoSize=1080x1920, displaySize=1920.00x1080.00, minCrop=Offset(0.0, 0.0), maxCrop=Offset(0.6, 1.0), preferredAspect=1.0`.
- `[NativeVideoExportService] Android rotated crop rect display-space: left=0.00, top=0.00, width=1080.00, height=1080.00`.
- `Media3Transformer: Original video: 1920x1080, rotation=90` and `Crop: [0,0 1080x1080]`.
- No `VideoCropUtil` entries yet (FFmpeg path not exercised in this run).

**Analysis**
- The editor UI shows the video corrected to portrait (via `RotatedBox` and swapped dimensions). The crop handles operate in this display-space.
- In the native export path, we currently pass a display-space `cropRect` for Android when metadata rotation is odd (90°/270°), relying on the native plugin to transform it.
- Logs from `Media3Transformer` strongly suggest the crop is applied in file-space (1920×1080) without accounting for metadata rotation, using the provided `cropRect` verbatim: `Crop: [0,0 1080x1080]`.
- Therefore, when the user selects the top square of the portrait, the native path ends up cropping the top-left square of the underlying landscape file (not the top of the portrait), producing correct output size but wrong content.

**What Worked**
- Rotation detection (metadata=90°) and UI rotation correction are correct.
- Aspect ratio constraint to 1:1 produced a square crop computed as 1080×1080.
- Export completed and emitted the expected 1080×1080 dimensions.

**What Didn’t**
- Mapping of the selected display-space crop to file-space for Android videos with 90°/270° metadata rotation in the native export path.
- Assumption that the native plugin would transform a display-space `cropRect` appears incorrect for our version/usage: it applies the crop directly in file-space.

**Root Cause (Hypothesis)**
- On Android with metadata rotation=90°/270°, we must perform explicit display→file coordinate mapping before passing the crop to native export. Currently, for the native path we pass display coordinates; the plugin crops in file-space without applying the rotation transform, leading to spatial mismatch.

**Proposed Fix**
- For the native export path on Android when `metadataRotation % 180 != 0`:
  - Compute the crop in file-space using the selected display-space rectangle and the rotation. We already implemented a robust mapping utility (`lib/ui/tools/editor/crop_coordinate_mapper.dart`) and enhanced logic in `VideoCropUtil` for FFmpeg.
  - Replace the current Android-rotated branch in `NativeVideoExportService` to:
    1) Build the display-space rect (as done now) to respect aspect ratio and clamping.
    2) Map it to file-space via `CropCoordinateMapper.mapToFileSpace(...)`.
    3) Pass the mapped file-space rect to `NativeVideoEditor.processVideo`.
- Keep FFmpeg path as-is, where we already generate a corrected `crop=` filter (`-noautorotate` plus recalculated `w:h:x:y`).

**Validation Plan**
- Scenario A (rotation=90°):
  - Source: 1920×1080 file with metadata=90° (portrait display 1080×1920).
  - Select top square (0..1080 on portrait), export via native path.
  - Expectation: 1080×1080 output with content matching the top of the portrait.
- Scenario B (rotation=270°):
  - Same test with a 270° clip; expect correct quadrant mapping.
- Scenario C (no rotation):
  - Ensure unchanged behavior; both native and FFmpeg paths align.
- Scenario D (FFmpeg fallback):
  - Force FFmpeg (internal user toggle off), repeat A/B and ensure `VideoCropUtil` logs match the native path results.

**Additional Notes**
- Consider baking even-dimension constraints (x,y,w,h all even) to keep MediaCodec happy; current logic floors to even in the mapper.
- If the plugin ever adds display-space crop APIs for rotated sources, we can simplify; until then, we should consistently pass file-space rectangles on Android.
