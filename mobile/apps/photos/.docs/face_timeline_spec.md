## Faces Timeline Feature Spec

### Objective
Deliver an on-device, auto-playing “faces timeline” for eligible named people that highlights their visual journey over the years and enables sharing a rendered video.

### Eligibility & Precomputation
- Run background precomputation per person after ML syncs or people data changes.
- Skip people marked ignored/hidden or lacking ≥5 distinct calendar years that each contribute ≥4 faces (based on file `creationTime`); a year only counts toward eligibility if it independently meets that four-face threshold.
- Group faces by year, sort chronologically, and select four samples spread across the year (prefer quarterly spacing; gracefully accept uneven distributions).
- Store the resulting ordered face list with metadata (faceID, fileID, creationTime, optional crop bytes) in a local cache keyed by personID.
- Persist the ordered timeline metadata for all people in a single JSON cache (e.g., `faces_timeline/cache.json`) that maps each eligible `personID` to the face ordering, timestamps, and auxiliary playback data; continue to rely on the existing face thumbnail cache for the actual crop bytes.
- Precompute and cache full face crops via existing `MLDataDB.getCoverFaceForPerson` + `getCachedFaceCrops`; avoid runtime generation.
- Persist readiness state so UI banners only surface when a valid timeline exists; invalidate cache when clusters update or new faces arrive.

### People Page Surfacing
- Add a new “Faces timeline” banner in the `PeoplePage` header area alongside other suggestions.
- Banner appears only after precomputation succeeds; tap navigates to a dedicated timeline route.
- Suppress banner if the timeline export is in progress (tracked with the same lightweight pattern used in `lib/ui/tools/similar_images_page.dart`) or the person becomes ineligible.
- Style the entry as a “Memory Lane” pill with the first timeline face crop shown on the left, a sparkle accent, and a trailing chevron so the banner previews exactly what the playback will start with.

### Timeline Playback Experience
- `FacesTimelinePage` presents cached crops in chronological order with cross-fade or quick dissolve transitions (≈0.8–1.0 s per frame) and optional manual controls (pause/play, next/back).
- Preload the next frame into memory to avoid jank; fall back gracefully if a crop is missing.
- Full-bleed presentation with neutral background and subtle parallax is acceptable; no additional chrome beyond playback & share controls.

### Captioning & Time Context
- Compute per-frame captions displayed at the bottom:
  - If `person.data.birthDate` available (yyyy-MM-dd), show “\<Name> was X years old”.
  - Otherwise show “X years ago”.
- Animate the numeric value smoothly as frames advance using the difference between the face creation time and birthdate or the current time.

### Sharing Flow (Iteration 2)
- Defer full export/render work to the second iteration; the first iteration ships playback-only UI with the share affordance hidden or disabled.
- When implemented, provide a share action on the playback page.
- MVP export: render the sequence to MP4 using `VideoMemoryService` (FFmpeg) at ~1080×1080, 1 s per frame, ≈0.2 s cross-fade, including caption overlays.
- Save the video to a temporary location and invoke the system share sheet; clean up temp outputs after sharing.
- If export fails, notify the user and leave the share action disabled until a retry succeeds.

### Performance & Reliability
- Execute precomputation in a background isolate with throttling (e.g., max once per person per day) to limit resource spikes.
- Ensure the timeline plays offline by relying on cached crops and locally stored payloads.
- Add logging (non-PII) for eligibility results, banner impressions, playback starts, and share attempts.

### Testing & QA
- Unit-test the yearly selection algorithm and eligibility gating.
- Widget-test banner visibility logic on `PeoplePage`.
- Manual QA checklist: timeline playback smoothness, caption correctness with/without birthdate, share flow success, failure fallback, offline playback.

### Privacy & Compliance
- All processing remains on-device, leveraging existing encrypted ML datasets; no new remote calls.
- Respect cache eviction rules to avoid leaking face crops beyond required usage.

### Implementation Findings & Follow-Up
- **[Priority: Medium] Background recompute drops people.** The current implementation caps the per-person precompute queue at 200 entries (`lib/services/faces_timeline/faces_timeline_service.dart`) and the queue helper (`lib/utils/standalone/task_queue.dart`) evicts the oldest task when that cap is exceeded. On accounts with >200 named people this means timelines silently never compute for most users. We need a follow-up that guarantees every person is processed (larger cap, disk-backed backlog, or a smarter scheduling policy) and adds logging/metrics so we can detect backlogs.
- **[Priority: Low] Share affordance still active.** Iteration 1 calls for the share UI to be hidden or disabled. Right now the share icon in `FacesTimelinePage` still invokes `onPressed` and only shows a “coming soon” snackbar. Please disable the control until export ships so QA can verify the correct state.
- **[Priority: Medium] Forced recompute flag dropped.** `FacesTimelineService.schedulePersonRecompute` enqueues work via `TaskQueue.addTask`, which deduplicates only by `id` and retains the closure from the first enqueue. Later invocations (even with `force: true`) cannot change the captured `force`/`trigger` values, so a forced request can still run as non-forced and be skipped by the 24 h cooldown. Ensure the queued task reflects the latest flags so forced recomputes always bypass throttling.
