# Ente Wrapped 2025 — Engineering Plan

Purpose: a practical, day-to-day implementation guide that expands the spec’s Engineering Plan into concrete steps, code scaffolds, file touchpoints, and a progress tracker. i18n is deferred; everything is behind `flagService.enteWrapped` (pointing to `flagService.internalUser` ). All compute runs in one single big isolate call.

Scope & Constraints
- On-device only; reuse existing ML infra (CLIP, faces, smart memories, EXIF/location).
- Single isolate compute; caching + resume index; shareable PNG cards.
- Entry: home gallery banner → viewer; discovery entry after banner dismiss; optional local notification.

Architecture Overview
- Feature flag: gate all Wrapped UI and entry flows by `flagService.enteWrapped`.
- Engine: `WrappedEngine` orchestrates one-shot compute in an isolate and returns an ordered list of `WrappedCard`s + badge + small stats.
- Cache: per-year snapshot persisted locally
- Resume: store last viewed index in `LocalSettings` (e.g., `ls.wrapped_2025_resume_index`).
- UI: Banner in home gallery; discovery section entry; viewer (autoplay stories); share exporter.

Core Data Sources
- CLIP image embeddings (MLDataDB/ClipVectorDB), CLIP text embeddings via `textEmbeddingsCacheService`.
- Faces/clusters via `MLDataDB` + `PersonService`.
- Time/event clustering patterns via `SmartMemoriesService`.
- EXIF/GPS/location via `exif_util.dart` + `location_service.dart`.
- Favorites via `FavoritesService`.

Data Contracts
```dart
enum WrappedCardType {
  statsTotals,
  statsVelocity,
  busiestDay,
  longestStreak,
  longestGap,
  topPerson,
  topThreePeople,
  groupVsSolo,
  newFaces,
  newPlaces,
  topCities,
  mostVisitedSpot,
  thenAndNow,
  yearInColor,
  monochrome,
  panoramas,
  biggestShot,
  top9Wow,
  favorites,
  albums,
  topEvents,
  bestOf25,
  badge,
}

class MediaRef {
  final int uploadedFileID; // EnteFile.uploadedFileID
  const MediaRef(this.uploadedFileID);
}

class WrappedCard {
  final WrappedCardType type;
  final String title; // EN-only MVP
  final String? subtitle;
  final List<MediaRef> media; // 0–9, prefer 1 or 3/4/9
  final Map<String, Object?> meta; // small stats for rendering copy
  const WrappedCard({
    required this.type,
    required this.title,
    this.subtitle,
    this.media = const [],
    this.meta = const {},
  });
}

class WrappedResult {
  final List<WrappedCard> cards; // ordered for playback
  final int year;
  final String? badgeKey; // e.g. 'traveler', 'people_person'
  const WrappedResult({required this.cards, required this.year, this.badgeKey});
}
```

Feature Flag & Resume Index
```dart
// Gate all UI surfaces
if (!flagService.enteWrapped) return const SizedBox.shrink();

// LocalSettings (add keys)
// keys: 'ls.wrapped_2025_resume_index' (int), 'ls.wrapped_2025_complete' (bool)
extension WrappedLocalSettings on LocalSettings {
  static const _kWrappedResumeIndex = 'ls.wrapped_2025_resume_index';
  static const _kWrappedComplete = 'ls.wrapped_2025_complete';

  int wrapped2025ResumeIndex() => _prefs.getInt(_kWrappedResumeIndex) ?? 0;
  Future<void> setWrapped2025ResumeIndex(int index) =>
      _prefs.setInt(_kWrappedResumeIndex, index);

  bool wrapped2025Complete() => _prefs.getBool(_kWrappedComplete) ?? false;
  Future<void> setWrapped2025Complete(bool v) =>
      _prefs.setBool(_kWrappedComplete, v);
}
```

WrappedEngine (single isolate compute)
```dart
// lib/services/wrapped/wrapped_engine.dart
class WrappedEngine {
  static Future<WrappedResult> compute({required int year}) async {
    final now = DateTime.now();
    // Gather minimal args on main isolate
    return await Computer.shared().compute(
      _computeIsolate,
      param: {
        'year': year,
        'now': now,
        // You may pass debug flags, thresholds, etc.
      },
      taskName: 'wrapped_compute_$year',
    ) as WrappedResult;
  }

  static Future<WrappedResult> _computeIsolate(Map args) async {
    final int year = args['year'] as int;
    final DateTime now = args['now'] as DateTime;

    // 1) Load inputs (similar to SmartMemoriesService)
    final Set<EnteFile> files = Set.from(
      await SearchService.instance.getAllFilesForSearch(),
    ).where((f) => f.uploadedFileID != null && f.creationTime != null).toSet();
    final persons = await PersonService.instance.getPersons();
    final cities = await locationService.getCities();
    final fileIdToFaces = await MLDataDB.instance.getFileIDsToFacesWithoutEmbedding();
    final embeddings = await MLDataDB.instance.getAllClipVectors();

    // Precompute maps for quick scoring
    final fileIDToEmbedding = {
      for (final e in embeddings) e.fileID: e,
    };

    // 2) Candidate generation per chapter (see below for functions)
    final candidates = <WrappedCard>[];
    candidates.addAll(await _buildStatsCards(files, year));
    candidates.addAll(await _buildPeopleCards(files, persons, fileIdToFaces));
    candidates.addAll(await _buildPlacesCards(files, cities));
    candidates.addAll(await _buildAestheticCards(files, fileIDToEmbedding));
    candidates.addAll(await _buildCurationCards(files));
    candidates.addAll(await _buildNarrativeCards(files, fileIDToEmbedding));

    // 3) Scoring + diversity + selection (target 12–18)
    final selected = _selectCards(candidates, target: 15);

    // 4) Badge selection
    final badgeKey = _computeBadge(selected, files, persons);

    return WrappedResult(cards: selected, year: year, badgeKey: badgeKey);
  }
}
```

Candidate Generation (sketches)
```dart
static Future<List<WrappedCard>> _buildStatsCards(Set<EnteFile> files, int year) async {
  final stats = _computeYearStats(files, year);
  return [
    WrappedCard(
      type: WrappedCardType.statsTotals,
      title: 'You captured ${stats.totalPhotos} photos',
      meta: {'photos': stats.totalPhotos, 'videos': stats.totalVideos},
    ),
    if (stats.longestStreakDays > 0)
      WrappedCard(
        type: WrappedCardType.longestStreak,
        title: 'Longest streak: ${stats.longestStreakDays} days',
      ),
    // ... more compact cards
  ];
}

static Future<List<WrappedCard>> _buildAestheticCards(
  Set<EnteFile> files,
  Map<int, EmbeddingVector> fileIDToEmbedding,
) async {
  // Example: Top 9 wow via CLIP queries intersection
  final textVec1 = Vector.fromList(await textEmbeddingsCacheService.getEmbedding('photo of a beautiful scene'));
  final textVec2 = Vector.fromList(await textEmbeddingsCacheService.getEmbedding('professional photography'));

  final scored = <int, double>{};
  for (final f in files) {
    final id = f.uploadedFileID;
    if (id == null) continue;
    final emb = fileIDToEmbedding[id];
    if (emb == null) continue;
    final s1 = emb.vector.dot(textVec1);
    final s2 = emb.vector.dot(textVec2);
    final score = (s1 + s2) / 2.0;
    if (score > 0.25) scored[id] = score;
  }
  final top = scored.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final media = top.take(9).map((e) => MediaRef(e.key)).toList();
  if (media.length < 6) return [];
  return [
    WrappedCard(
      type: WrappedCardType.top9Wow,
      title: 'Your top 9 by pure wow',
      media: media,
    ),
  ];
}
```

Selection & Badge (sketches)
```dart
static List<WrappedCard> _selectCards(List<WrappedCard> candidates, {int target = 15}) {
  // Simplified: score by type priority + meta confidence; enforce diversity by type caps.
  final typeCaps = <WrappedCardType, int>{
    WrappedCardType.statsTotals: 1,
    WrappedCardType.top9Wow: 1,
    WrappedCardType.badge: 1,
    // generic cap 2 otherwise
  };
  final out = <WrappedCard>[];
  final usedByType = <WrappedCardType, int>{};
  for (final c in candidates) {
    final cap = typeCaps[c.type] ?? 2;
    final used = usedByType[c.type] ?? 0;
    if (used >= cap) continue;
    out.add(c);
    usedByType[c.type] = used + 1;
    if (out.length >= target) break;
  }
  // Ensure badge at end
  if (!out.any((c) => c.type == WrappedCardType.badge)) {
    out.add(WrappedCard(type: WrappedCardType.badge, title: 'Your 2025 badge'));
  }
  return out;
}

static String _computeBadge(
  List<WrappedCard> selected,
  Set<EnteFile> files,
  List<PersonEntity> persons,
) {
  // Apply persona rules; return one key
  return 'traveler';
}
```

Cache Plan
- `WrappedCacheService`
  - Persist `WrappedResult` snapshot per year (e.g., JSON in app documents: `wrapped/2025.json` optionally gzipped).
  - Store `updatedAt` and input hash (counts of files, clip size, last person sync time, etc.).
  - Invalidate on: `LocalPhotosUpdatedEvent`, `FilesUpdatedEvent`, `EmbeddingUpdatedEvent`, `PeopleChangedEvent`.
  - API:
    - `Future<WrappedResult?> get(year)`; `Future<void> put(year, result);` `Future<void> invalidate(year);`

UI Plan
- Home Banner (gallery top)
  - Visible if `flagService.enteWrapped && cache.has(year) && !localSettings.wrapped2025Complete()`.
  - Tap → `WrappedViewerPage(result: cached, startIndex: localSettings.wrapped2025ResumeIndex())`.
  - After completion, hide banner; move entry to discovery.
  - Snippet:
```dart
if (flagService.enteWrapped && wrappedResult != null && !localSettings.wrapped2025Complete()) ...[
  WrappedHomeBanner(
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WrappedViewerPage(
          result: wrappedResult!,
          startIndex: localSettings.wrapped2025ResumeIndex(),
        ),
      ),
    ),
  )
]
```

- Discovery Entry
  - Add “Wrapped 2025” section below Locations when banner hidden, for ~1 month.
  - Tap → same navigation as banner.

- Viewer (autoplay, resume)
  - Use a simple `PageView` + timer driving autoplay or repurpose `FullScreenMemory` mechanics.
  - Update resume index on page changes; clear on completion.
  - Share action uses `RepaintBoundary` to export PNG per card.
```dart
class WrappedViewerPage extends StatefulWidget {
  final WrappedResult result;
  final int startIndex;
  const WrappedViewerPage({required this.result, this.startIndex = 0, super.key});
  @override State<WrappedViewerPage> createState() => _WrappedViewerPageState();
}

class _WrappedViewerPageState extends State<WrappedViewerPage> {
  late final PageController _pc;
  int _index = 0;
  @override void initState() { super.initState(); _index = widget.startIndex; _pc = PageController(initialPage: _index); }
  void _onPageChanged(int i) { setState(() => _index = i); localSettings.setWrapped2025ResumeIndex(i); }
  void _onComplete() { localSettings.setWrapped2025Complete(true); Navigator.pop(context); }
  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pc,
        onPageChanged: _onPageChanged,
        itemCount: widget.result.cards.length,
        itemBuilder: (ctx, i) => WrappedCardView(card: widget.result.cards[i], onShare: () {/* export */}),
      ),
      // Progress UI + auto-advance timer omitted for brevity
    );
  }
}
```

Notifications (optional MVP)
- Local notification: “Your 2025 Wrapped is ready” → deep link to viewer.
- Respect permissions; only for internal users.

Validation & Performance
- Compute occurs off main isolate; batch vector ops; avoid large copies.
- Use caches for text embeddings; reuse MLDataDB calls as in `SmartMemoriesService`.
- Keep per-card media to ≤9.

Risks & Mitigations
- Sparse libraries → don't show anything below minimum, otherwise stick to fallback set (Stats + Top9 + Favorites + Badge).
- Incorrect inferences → soft copy, high thresholds.
- Performance → precompute + cache.

Open Decisions
- Cache store format (JSON vs SQLite table) — start with JSON, revisit if size grows.
- Use `FullScreenMemory` vs custom viewer — create separate custom viewer for control, borrowing many elements from `FullScreenMemory` as a starting point. 

Milestones & Checklist
- [ ] Create `lib/services/wrapped/wrapped_engine.dart` with isolate compute stub
- [ ] Implement candidate builders (stats, people, places, aesthetics, curation, narrative)
- [ ] Add selection/diversity + badge logic
- [ ] Add `WrappedCacheService` (file-based JSON) + invalidation hooks
- [ ] Add LocalSettings extension for resume/complete
- [ ] Add Home Banner widget + wiring in gallery (gated)
- [ ] Add Discovery entry + gating + expiry window
- [ ] Implement `WrappedViewerPage` (autoplay, progress, resume)
- [ ] Implement share exporter (RepaintBoundary → PNG) + “Save all cards” flow
- [ ] Optional: local notification trigger + deep link
- [ ] QA: sparse vs rich libraries, performance, correctness
