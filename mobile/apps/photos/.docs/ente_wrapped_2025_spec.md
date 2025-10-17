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

1. Stats & Rhythm

- Totals: photos, videos, storage captured.
- GitHub like contribution-graph based on photo capture dates
- Velocity: avg/day; busiest month; contribution heatmap (compact).
- Busiest day; longest streak; longest gap.

2. People

- Most photographed person; top 3 collage; group vs solo; “new faces met”.

3. Places

- New places count; top cities; most‑visited spot; optional “Then & Now”.

4. Aesthetics & Scenes

- Year‑in‑color palette; monochrome moments; panoramas; biggest shot; “Top 9 wow”.

5. Technique & Habits

- New device; live/motion photos rate; front vs rear; bursts; hour‑of‑day.

6. Curation & Collaboration

- Favorites count; albums created; share activity highlights.

7. Narrative Finale

- Top 3 events (time+place clusters) and a “Best of 25” micro‑reel.

8. Badge

- A single, fun persona badge; exportable as a share card.

Cards are short, legible, and visually anchored by 1–9 photos. Avoid textual overload.
A standard card has one image with a fun descriptive text about the statistic. If we don't know what image to take then we can just use a colourful one and blurhash it. And if we know what image to use and
more images are appropriate then we can add more. But the basic card is one image and a nice text.

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

Assign exactly one persona using mutually exclusive rules, with tie‑breakers:

- Traveler: ≥ 6 new cities or ≥ 2 new countries; trips present
- People Person: top person appears in ≥ 25% of 2025 photos and group photos ≥ 35%
- Pet Parent: pet photos ≥ 5% of 2025; CLIP cat/dog high confidence
- Foodie: food photos ≥ 5% and ≥ 50 photos total
- Golden Hour Hunter: golden/blue hour ≥ 30% of 2025 captures (approx)
- Night Owl: ≥ 20% photos between 22:00–02:00
- Curator: favorites ratio ≥ 10% and ≥ 100 favorites in 2025
- Panorama Pro: ≥ 30 panoramas or ≥ 2% panoramas
- Marathoner: longest streak ≥ 30 days
- Minimalist Shooter: total photos low but high favorites ratio (e.g., <1k photos, >15% favorites)
- Sports photographer: many burst photos
- Group photographer: relatively many photos shared with other people and/or many other people in photos

Badge card shows badge name, short line of copy, and 1–4 representative thumbnails. Always exportable.

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
- Local notifications (optional for MVP)
  - Local only (no remote). Tap navigates to viewer at resume index.
  - Gated by `internalUser` and user notification permission.
- Basic card structure & flow
  - Card model `WrappedCard { type, title, subtitle, mediaRefs, shareLayout }`.
  - Viewer: autoplay story, progress bar, tap left/right to nav, pause on touch.
  - Share action per card: export a designed PNG (portrait 1080×1920; square optional later).
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
  - Persist per‑year results (e.g., simple serialized snapshot). Invalidate on ML updates or when user adds new 2025 media.
  - Store a lightweight hash of inputs to detect staleness.
- Eligibility & fallbacks
  - Enforce thresholds; degrade to minimal set (Stats + Top9 + Favorites + Badge) if sparse.

Phase 2 — Depth & polish

- Add Then & Now, live/motion, front vs rear, bursts, golden/blue hour.
- Year‑in‑color palette generation and contribution heatmap card.
- More badges; improved diversity and scoring.

Phase 3 — Advanced

- Optional video export for “Best of 25”.

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
- Do we surface cross‑year comparisons (“+X% vs 2024”) broadly or only in stats? Only in stats, if at all.

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

—
This spec is grounded in existing code paths for CLIP, faces, locations, and memories. It prioritizes on‑device computation, small‑copy visuals, and share‑first moments while keeping overlap low via candidate scoring and diversity constraints.
