# Ente Wrapped 2025 — Product Spec (Codex)

## Summary

- Year-end, auto‑curated, story‑style recap generated fully on‑device from the user’s 2025 photos, using the metadata and ML indices (faces, CLIP, time, and location).
- Goals: delight, reflection, and effortless sharing, while preserving Ente’s privacy and zero‑knowledge principles.
- Format: a lean, autoplay “story” with minimal swiping, tight, fun copy, and selectable share cards. One fun, personalized badge crowns the finale.

## Objectives & Success

- Delight: users watch end‑to‑end without friction; feel recognized and surprised.
- Share: users easily share 1–3 highlights as images or short grids.
- Privacy: compute on‑device, never exfiltrate private content or names.

Success signals (local, privacy‑friendly)

- Story completion rate
- Shares initiated per user (share intent button taps)
- Card saves/exports per user
- Clicks into related surfaces (People, Locations, Albums, Favorites)

## Guardrails (Privacy & UX)

- On‑device only; no remote inference. Use existing local ML DBs (CLIP, face clusters) and EXIF/location.
- Gate content by confidence and data sufficiency; gracefully skip sparse sections.
- Single, tasteful brand style; no noisy charts unless they read clean in 1–2s.
- The cards can be dynamic through animations, but not statefull/interactive.

## User Experience

- Entry points
  - Home banner on top of home gallery: “Your 2025 Wrapped is ready” (if eligibility met and calculations done).
    - Disappears after the user has seen the wrapped completely, or partially multiple times
  - After the home banner disappears, the Wrapped is added as a separate section to the discovery tab, right above the locations section.
    - It stays there for another month.
  - Notifications (local): “We made you a 2025 recap.”
  - Put all entry points initially behind a feature flag that points to `internalUsers`
- Flow
  - Intro title card → short “chapters” → finale badge → call‑to‑action.
  - Autoplay with progress bar; Tap sides to skip/rewind; pause on touch.
  - Each card has a compact “Share” action that exports a designed image.
- Sharing
  - Export single cards as images (1080×1920 portrait).
  - Optional “Save All Cards” to an album of images in Ente.

## Content Architecture (Chapters)

Wrapped assembles a diverse subset of the following, tuned per user:

1. Stats & Rhythm (should not include shared files, only files owned by the user)

- Totals: photos, videos, storage captured.
- Velocity: avg/day; busiest month; longest streak
- Busiest day;
- GitHub like contribution-graph based on photo capture dates

2. People

- Most photographed person; top 3 collage; group vs solo; “new faces met”.

3. Places

- New places count; top cities; most‑visited spot; optional “Then & Now”.

4. Aesthetics & Scenes

- Year‑in‑color palette; monochrome moments; “Top 9 wow”.

5. Badge

- A single, fun persona badge; exportable as a share card.

Cards are short, legible, and visually anchored by 1–9 photos. Avoid textual overload.
A standard card has one image with a fun descriptive text about the statistic. If we don't know what image to take then we can just use a colourful one and blurhash it. And if we know what image to use and
more images are appropriate then we can add more. But the basic card is one image and a nice text.

### Additional optional cards

1. Technique & Habits

- New device; live/motion photos rate; front vs rear; bursts; hour‑of‑day.

2. Curation & Collaboration

- Favorites count; albums created; share activity highlights.

3. Narrative Finale

- Top 3 events (time+place clusters) and a “Best of 25” micro‑reel.

## Eligibility & Fallbacks

- ML enabled
- Minimum: ≥ 200 photos with ≥ 60% CLIP+face coverage.
- If sparse: reduce chapters, use a card only if possible; prefer Stats + Top 9 + Favorites + Badge.
- If ML disabled or coverage < 25%: show a teaser (“Enable ML to see your 2025”).

## Data Sources (Existing Infra)

- CLIP image embeddings: `lib/db/ml/schema.dart` (`clip` table), vector DB `ClipVectorDB`.
- CLIP text embeddings: on‑device encoder `ClipTextEncoder` with cached results (`text_embeddings_cache`).
- Faces & clusters: `faces`, `face_clusters`, `cluster_person` with blur scores; `PersonService` for named people.
- Time & event clustering: existing “smart memories” pipelines (`SmartMemoriesService`).
- EXIF, GPS, motion, panorama: `exif_util.dart` + `location_service.dart` (world cities matching).
- Favorites, albums, shares: `FavoritesService`, albums/sharing services.

## Algorithms & Computation

All heavy work runs on isolates and caches results. Perform all calculations in one single isolate call to minimize main‑isolate overhead and memory churn. Use `SmartMemoriesService` as a reference for the structure and args passing.

General selection framework

- Generate candidate cards per category with a score = impact × confidence × novelty.
- Enforce diversity with category caps and “no‑overlap” constraints on media sets.
- Target 12–18 cards total; max 2–3 per chapter.

Stats (fast, deterministic)

- Totals, velocity, busiest day/month, streaks/gaps from creation timestamps.
- Contribution heatmap: 7×53 bitmap grid (year calendar), low‑ink style.

People

- Most photographed: named person with most photos in 2025.
- Top 3 collage: three named persons with most 2025 appearances.
- Group vs solo: faces/photo threshold (≥3 = group).
- New faces: clusters with first appearance in 2025 (min size ≥10).
- Confidence: require named clusters for “Most/Top 3”, else fall back to “Loved ones moments.”

Places

- New places: unique city/country via `LocationService` circle‑match; dedupe by distance.
- Top cities: top 3 by count.
- Most‑visited spot: densest 100m geohash bucket (approx via distance threshold clustering).
- Then & Now: same city radius, years differ ±30 days; pick best visual pair.

Aesthetics & Scenes

- Year in Color: use CLIP queries “strongly red/blue/green…” with tight thresholds to curate swatches.
- Monochrome: CLIP text query “black‑and‑white photo”.
- Panoramas: EXIF `CustomRendered == 6` or aspect ratio > 2.2.
- Biggest shot: max resolution still.
- Top 9 wow: CLIP positive prompt intersections (multiple curated queries) with diversity constraints; 3×3.

Technique & Habits

- New device: first‑seen camera model in 2025 (if available in metadata).
- Live/Motion: XMP/motion tags.
- Front vs rear: EXIF camera facing heuristics.
- Bursts: near‑duplicate sequences within ~1s with similar EXIF.
- Hour‑of‑day: distribution; “Golden hour chaser” via hour buckets (fallback): 5–8am, 4–7pm; “Blue hour” 6–7am, 6–8pm, tuned by latitude bands when GPS present.

Curation & Collaboration

- Favorites: count; top month.
- Albums: created count; most‑filled.
- Sharing: shared albums created or contributors added.

Narrative

- Top 3 events: time+place clustering (reuse SmartMemories trip/event clustering), rank by density and variety.
- Best of 25: select across year using CLIP similarity + faces of named persons + diversity + favorites; autoplay grid or quick reel.

## Ideas Evaluation (from `.docs/ente_wrapped_ideas.md`)

Doable now (green)

- Totals, velocity, busiest day/month, streaks/gaps, distributions (hour/day/season approx)
- Most photographed person; Top 3 collage; group vs solo; new faces
- New places; top cities; most‑visited spot; Then & Now (approx by city radius)
- Year in color; monochrome; panoramas; biggest shot; Top 9 wow
- New device; live/motion rate; front vs rear; bursts (heuristic)
- Pets; foodie via CLIP queries; favorites; albums; best‑of reel; top 3 events

With caveats (amber)

- Golden vs Blue hour: without exact sunrise/sunset, use hour buckets or coarse lat‑band rules; annotate “approximate”.
- Altitude range: only if GPS exif with altitude exists; otherwise skip.

Defer (red)

- Full reverse‑geocoding by address names: avoid external network; stick to cities list.
- Auto‑generated video with music: heavy; follow‑up phase after MVP.

## Badge System (share‑first)

Assign exactly one persona with clear, brag‑friendly copy with a nice metric. Selection is deterministic and privacy‑preserving (local compute only). Every user must get a badge; if no persona passes thresholds, we award a universal fallback.

Core personas (this year only)

- Consistency Champ

  - Signal: longest streak and active‑days ratio.
  - Gate: daysWithCaptures >= 15.
  - Score: 0.6 _ min(1, longestStreakDays/14) + 0.4 _ min(1, (daysWithCaptures/elapsedDays)/0.5).
  - Copy: "You kept the lens alive — {longestStreakDays} days straight."
  - Brag chips: "Active days: {daysWithCaptures}".

- Group Photographer

  - Signal: share of group moments (>=3 faces) within all face moments.
  - Gate: totalFaceMoments >= 20 and groupMoments >= 12.
  - Score: min(1, (groupMoments/totalFaceMoments)/0.55).
  - Copy: "{groupPercent}% with the crew — memories shared."
  - Brag chips: "Group moments: {groupMoments}".

- Portrait Pro

  - Signal: share of solo moments within all face moments.
  - Gate: totalFaceMoments >= 20 and soloMoments >= 12.
  - Score: min(1, (soloMoments/totalFaceMoments)/0.60).
  - Copy: "{soloPercent}% one‑on‑one — portrait season."
  - Brag chips: "Solo portraits: {soloMoments}".

- People Person

  - Signal: coverage of people overall (face moments relative to all captures). Avoids repeating "X starred" card.
  - Gate: totalCount >= 80 and totalFaceMoments >= 16.
  - Score: min(1, (totalFaceMoments/totalCount)/0.50).
  - Copy: "People in {peopleShare}% of your memories."
  - Brag chips: "Moments with people: {totalFaceMoments}".

- Globetrotter

  - Signal: this‑year place breadth: unique cities and countries seen in 2025 (from city/spot clustering + city list).
  - Gate: geoCount >= 40 and (uniqueCities >= 3 or uniqueCountries >= 2).
  - Score: 0.6 _ min(1, uniqueCities/5) + 0.4 _ min(1, uniqueCountries/3).
  - Copy: "You roamed {uniqueCities} cities across {uniqueCountries} countries."
  - Brag chips: "Geotagged: {geoShare}%".
  - Note: strictly 2025 captures; not "new" across lifetime.

- Time‑of‑Day Champ (Night Owl or Early Bird)

  - Signal: dominance of late‑night (20:00–04:59) or early‑morning (05:00–09:59) captures.
  - Gate: totalCount >= 60; chosen bucket share sufficient.
  - Score: min(1, dominantShare/0.35); require score >= 0.50.
  - Copy (Night Owl): "{nightShare}% after dark — best work under the stars."
  - Copy (Early Bird): "{morningShare}% at first light — early magic."

- Pet Parent

  - Signal: CLIP text embedding for pets (cat/dog) across the year.
  - Gate: petShare >= 10% and petCount >= 6.
  - Score: min(1, petShare/0.25).
  - Copy: "{petCount} pet portraits — {topPetGuess} stole the spotlight."
  - Brag chips: "Pets in {petShare}% of your shots."

- Minimalist Shooter

  - Signal: lower volume but steady intent (active days).
  - Gate: totalCount <= 150 and daysWithCaptures >= 12.
  - Score: 0.6 _ min(1, 150/max(1,totalCount)) + 0.4 _ min(1, (daysWithCaptures/elapsedDays)/0.5).
  - Copy: "Quality over quantity — {totalCount} thoughtful frames."
  - Brag chips: "Active days: {daysWithCaptures}".

- Curator

  - Signal: favorites behavior (from FavoritesService).
  - Gate: favoritesCount >= 60 or favoriteShare >= 20%.
  - Score: 0.5 _ min(1, favoritesCount/150) + 0.5 _ min(1, favoriteShare/0.3).
  - Copy: "You starred {favoritesCount} favorites."
  - Brag chips: "Keeps: {favoriteShare}%".

- Local Legend
  - Signal: repeated visits to a single spot (do not name the spot).
  - Gate: topSpotDistinctDays >= 3 and topSpotShare >= 15%.
  - Score: 0.7 _ min(1, topSpotShare/0.25) + 0.3 _ min(1, topSpotDistinctDays/6).
  - Copy: "Your regular hangout — {topSpotCount} memories across {topSpotDistinctDays} days."
  - Brag chips: "Most‑visited share: {topSpotShare}%".
  - De‑dup: suppress if a "Most Visited Spot" card is already in the story.

De‑prioritized / fallback personas

- Moment Maker

  - Gate: totalCount >= 100.
  - Score: 0.5 _ min(1, totalCount/800) + 0.5 _ min(1, averagePerDay/4).
  - Use only if none of the core personas pass their gates; copy: "You bottled {totalCount} memories — unstoppable."

- Live Mover
  - Gate: livePhotoCount >= 10.
  - Score: min(1, (livePhotoCount/max(1,photoCount))/0.30).
  - Use only if none of the core personas pass their gates; copy: "{liveShare}% of your photos move — stories in motion."

Universal fallback (guarantee)

- Memory Keeper
  - Always available if no other badge qualifies.
  - Copy: "You kept your memories safe — your {year}, preserved with heart."

Selection and UX rules

- Selection: compute all candidates; filter by gates; pick highest score.
- Tie‑breakers: (1) higher score, (2) larger underlying sample size for that signal, (3) deterministic seed (year + totalCount) for stable results.
- Uniqueness: badge copy must not duplicate earlier cards (e.g., People Person uses people coverage, not "X starred").
- This‑year only: all stats computed from the target year (2025).
- Debug builds: show all badge candidates sorted by score with a small score label and a "why" note; first item equals the chosen badge. Production shows only the chosen badge.
- Visuals: prototype with gradient backgrounds and simple glyphs; share card always exportable (portrait and square).

## Card Design System

- Visuals
  - Dark background, brand accent; large numerals where applicable.
  - Use 1–9 image grids; prefer human faces when copy references people.
- Copy style
  - Short, upbeat, human..
  - Examples:
    - “You captured 12,345 moments.”
    - “Longest streak: 42 days — the lens never slept.”
    - “{Name} starred in your year.” (only if named)
- Formats
  - Portrait 1080×1920 (story), Square 1080×1080 (feeds).
  - Local export as PNG; optional album save.

## Engineering Plan

Phase 0 — UI skeleton & flags

- Feature flag gating
  - Gate all entry points and the viewer behind a flag `flagService.enteWrapped` that points to `flagService.internalUser`.
  - Hide Wrapped UI completely for non‑internal users.
- Home gallery banner
  - Shows when eligibility + compute complete; tap opens Wrapped viewer at resume index.
  - Dismiss behavior: auto‑hide after full watch; or after partial watch 3 times.
- Discovery tab entry
  - Add a “Wrapped 2025” section below Locations. Visible after banner disappears, till January 15th 2026.
  - Same gating and tap behavior as banner.
- Basic card structure & flow
  - Card model `WrappedCard { type, title, subtitle, mediaRefs, shareLayout }`.
  - Viewer: autoplay story, progress bar, tap left/right to nav, pause on touch.
  - Viewer implementation: prefer a `PageView`-style carousel with timer-driven autoplay (or equivalent) that updates the resume index on every page change and clears state once the run completes.
  - There should be basic animations for moving the text and images to make it more interesting
  - Share action per card: export a designed PNG (portrait 1080×1920; square optional later)
- Resume state
  - Persist last viewed card index in `LocalSettings` (e.g., key `wrapped_2025_resume_index`).
  - Viewer reads this on open, updates it on page change; clear on completion.
  - Ignore i18n for MVP: copy is EN‑only.

Phase 1 — Engine, cache, single isolate compute

- WrappedEngine (compute + selection)
  - Single isolate call that performs the entire pipeline (eligibility → candidate generation → scoring/diversity → final card list) similar to `SmartMemoriesService.calcSmartMemories`.
  - Input: year, now, ML availability, caches, thresholds.
  - Output: ordered `List<WrappedCard>` + badge + lightweight stats for UI.
- Data sources
  - CLIP vectors (`MLDataDB` + `ClipVectorDB`), faces/persons (`PersonService` + `MLDataDB`), time/event clusters (`SmartMemoriesService` patterns), EXIF/GPS (`exif_util` + `location_service`).
- Caching
  - A `WrappedCacheService` persists each year’s snapshot as a JSON payload (e.g., `wrapped/2025.json`, optionally gzipped) alongside metadata such as `updatedAt` and an input hash.
- Eligibility & fallbacks
  - Enforce thresholds; degrade to minimal set (Stats + Top9 + Favorites + Badge) if sparse.

Phase 2 — Depth & polish

- Add Then & Now, live/motion, front vs rear, bursts, golden/blue hour.
- Year‑in‑color palette generation and contribution heatmap card.
- More badges; improved diversity and scoring.

Phase 3 — Advanced

- Optional video export for “Best of 25”.
- Optional: Local notifications (optional for MVP)
  - Local only (no remote). Tap navigates to viewer at resume index.
  - Gated by `internalUser` and user notification permission.

## Technical Notes

- Performance: do all scoring and selection on isolates; batch vector ops with `ClipVectorDB.computeBulkSimilarities`.
- Diversity: maintain a UsedMediaSet; avoid repeating the same file across multiple cards unless intentional (finale reel exception).
- Confidence thresholds
  - CLIP similarity ≥ 0.25 for broad classes; tighter for palette/mono.
  - Faces: min cluster size; prefer low blur.
- Accessibility: large fonts, high contrast; no dense charts without labels.

## Open Questions and answers behind it

- Music or sound? Likely no for MVP.
- Opt‑in for showing person names on share cards? No, sharing itself is already opt-in, so not needed. Just always show names.
- Should we let users edit badge if they disagree? No. we can offer “See more badges you earned” as fun alternative. But let's not add that in the MVP. The idea should be that any badge is nice, so the user will never disagree. It's a fine balance, but possible.
- Do we surface cross-year comparisons (“+X% vs 2024”) broadly or only in stats? Only in stats, if at all.

## Open Decisions

- Cache store format: start with JSON snapshots, revisit SQLite only if size becomes an issue.
- Viewer foundation: build a bespoke viewer that borrows interaction patterns from `FullScreenMemory` instead of reusing it verbatim.

## Risks & Mitigations

- Sparse data → Show fewer but stronger cards. We don't need to show a card if it doesn't work for the library.
- Wrong inferences → Keep copy soft; only show high‑confidence items.
- Performance → Precompute in single big isolate call and cache.

## Analytics (Privacy‑friendly, local)

- Log only local counters and timestamps; no content.
- Surface these in a local debug screen; do not transmit remotely by default.

## QA Checklist (per device)

- ML enabled, indexed library vs sparse library
- Named people vs unnamed faces
- Location‑rich vs no‑GPS libraries
- Performance on low‑end devices
- Share card rendering correctness (all locales)

## Deliverables

- Story experience with 12–18 cards per eligible user.
- Exportable share cards (portrait + square) for each shown item.
- Badge system and finale.

## Milestones & Progress

- [x] Create `lib/services/wrapped/wrapped_engine.dart` with isolate compute stub
- [x] Implement candidate builders (stats, people, places, aesthetics, curation, narrative)
- [x] Wire feature flag getter (`flagService.enteWrapped`)
- [x] Introduce `WrappedService` for entry gating
- [ ] Flesh out candidate builder implementations
  - [x] StatsCandidateBuilder
  - [ ] PeopleCandidateBuilder
  - [ ] PlacesCandidateBuilder
  - [ ] AestheticsCandidateBuilder
  - [ ] CurationCandidateBuilder
  - [ ] NarrativeCandidateBuilder
- [ ] Add selection/diversity + badge logic
- [x] Add `WrappedCacheService` (file-based JSON) + invalidation hooks
- [x] Add startup orchestration in wrapped service + debug recompute hook
- [x] Add LocalSettings extension for resume/complete
- [x] Add Home Banner widget + wiring in gallery (gated)
- [x] Add Discovery entry + gating + expiry window
- [x] Implement `WrappedViewerPage` (progress/resume; autoplay pending)
- [ ] Implement share exporter (RepaintBoundary → PNG) + “Save all cards” flow
- [ ] Optional: local notification trigger + deep link
- [ ] QA: sparse vs rich libraries, performance, correctness

—
This spec is grounded in existing code paths for CLIP, faces, locations, and memories. It prioritizes on‑device computation, small‑copy visuals, and share‑first moments while keeping overlap low via candidate scoring and diversity constraints.
