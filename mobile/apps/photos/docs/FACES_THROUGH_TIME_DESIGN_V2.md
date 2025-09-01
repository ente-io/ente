# Faces Through Time - Feature Design Document (Final MVP)

## Executive Summary

"Faces Through Time" is a delightful slideshow feature that automatically displays a person's face photos chronologically across all the years, creating a visual journey of how they've grown and changed. The feature includes simple sharing capabilities to help spread the joy and potentially grow the product organically.

## Core Requirements

### Eligibility Criteria

- **Minimum time span**: 7 consecutive years of photos
- **Photos per year**: At least 4 faces per year
- **Face quality**: Minimum face score of 0.85
- **Age requirement**: All photos must be from after the person turned 5 years old
- **Total faces**: Minimum 28 faces meeting above criteria

### Display Requirements

- **Faces per year**: Exactly 4 (using quantile selection)
- **Display duration**: 2 seconds per face
- **Format**: Single face at a time, full screen
- **Padding**: Standard 40% padding (use existing face crop logic)

## User Experience Flow

### 1. Progressive Discovery

When user navigates to `PeoplePage`:

```
1. Background eligibility check (instant, non-blocking)
2. If eligible → Check if already viewed
3. If not viewed → Start face selection & thumbnail generation
4. Generate thumbnails (max 4 concurrent)
5. When ready → Show banner at top of page
6. User taps banner → Opens slideshow, mark as viewed
```

### 2. Banner & Menu Logic

**First Time (Not Viewed)**:

- Show eye-catching banner at top of `PeoplePage`
- Text: "How [Name] grew over the years"
- Appears only when all thumbnails are ready

**After First View**:

- No banner shown
- Add menu option in top-right overflow menu
- Menu text: "Show face timeline"
- Clicking menu item opens slideshow directly

### 3. Slideshow Page

**Layout**:

- Full-screen face thumbnail display
- Age display OR relative time below face:
  - With DOB (age > 5): "Age 7 years 2 months"
  - With DOB (current year): "6 months ago"
  - Without DOB: "8 years ago"
- Minimal UI overlay
- Auto-advance every 2 seconds

**Interaction Controls**:

- **Tap center**: Pause/Resume
- **Tap and hold**: Pause (release to resume)
- **Tap left side**: Previous face
- **Tap right side**: Next face
- **Close button**: Top-left corner
- **Share button**: Top-right corner

## Face Selection Algorithm

### Simple Quantile Selection

For each eligible year:

1. Get all faces with score ≥ 0.85
2. Filter out faces where person age ≤ 4 years (if DOB available)
3. Sort faces by timestamp
4. Select faces at positions:
   - 1st percentile (earliest)
   - 25th percentile
   - 50th percentile (median)
   - 75th percentile

This ensures even distribution across the year without complex logic.

## Sharing Feature (MVP)

### Share Flow

1. User taps share button in slideshow
2. Generate temporary video file:
   - 1 second per face (faster than slideshow)
   - Include age/year text overlay
   - Add subtle Ente watermark
   - Resolution: 720p (balance quality/size)
3. Open system share sheet
4. Clean up temp file after sharing

### Video Generation

```dart
// Pseudocode for video generation
final frames = timeline.entries.map((entry) => {
  'image': faceThumbnail,
  'text': entry.ageText ?? entry.relativeTimeText,
  'duration': 1000, // 1 second
});
final videoPath = await generateVideo(frames, watermark: true);
Share.shareFiles([videoPath]);
```

### Privacy Considerations

- Strip all metadata from video
- Don't include person's name in video
- Watermark: "Created with Ente Photos"
- Temporary file deleted after share

## Technical Implementation

### Caching Strategy

**Cache Structure** (JSON file):

```json
{
  "personId": "person_123",
  "generatedAt": "2024-01-15T10:30:00Z",
  "faceIds": ["face_1", "face_2", ..., "face_28"],
  "hasBeenViewed": true,
  "version": 1
}
```

**Cache Implementation** (Similar to `similar_images_service.dart`):

```dart
Future<String> _getCachePath(String personId) async {
  final dir = await getApplicationSupportDirectory();
  return "${dir.path}/cache/faces_timeline_${personId}.json";
}

Future<void> _cacheTimeline(FaceTimeline timeline) async {
  final cachePath = await _getCachePath(timeline.personId);
  await writeToJsonFile(cachePath, timeline.toJson());
}
```

**Cache Rules**:

- Cache persists for 1 year
- Only invalidate if older than 1 year
- One cache file per person
- No limit on number of cached persons

### Thumbnail Generation

**Batch Processing**:

```dart
// Generate thumbnails in batches of 4
for (int i = 0; i < faceIds.length; i += 4) {
  final batch = faceIds.skip(i).take(4).toList();
  final thumbnails = await Future.wait(
    batch.map((faceId) => generateFaceThumbnail(faceId))
  );
  // Store thumbnails
}
```

**Use Existing Methods**:

```dart
// Use standard face cropping from face_thumbnail_cache.dart
final cropMap = await getCachedFaceCrops(
  file,
  faces,
  useFullFile: true,  // Always use full file for quality
  useTempCache: false, // Use persistent cache
);
```

### View State Tracking

**Storage**:

```dart
// Simple key-value storage for viewed state
final viewedKey = "faces_timeline_viewed_${personId}";
final hasViewed = prefs.getBool(viewedKey) ?? false;
if (!hasViewed) {
  // Show banner
}
// After viewing:
await prefs.setBool(viewedKey, true);
```

## Age Filtering Logic

### When DOB is Available

```dart
bool isEligibleFace(Face face, DateTime? dob, DateTime photoTime) {
  if (dob == null) return true;

  final ageAtPhoto = photoTime.difference(dob);
  final yearsOld = ageAtPhoto.inDays / 365.25;

  // Exclude photos where person was 4 or younger
  return yearsOld > 4.0;
}
```

### Eligibility Check Update

Must have 7 consecutive years where ALL photos are:

- After person turned 5 (if DOB known)
- Meeting quality threshold (score ≥ 0.85)

## Data Flow Summary

```
PeoplePage Load
    ↓
Check Eligibility (with age filter)
    ↓
Check if Viewed
    ├─→ Not Viewed: Show banner when ready
    └─→ Viewed: Add menu option
    ↓
User Interaction
    ↓
Load/Generate Timeline
    ↓
Show Slideshow
    ↓
Optional: Share as Video
```

## Implementation Components

### New Files Required

1. **Service**: `faces_through_time_service.dart`

   - Eligibility checking
   - Face selection logic
   - Cache management

2. **UI**: `faces_through_time_page.dart`

   - Slideshow display
   - Auto-advance logic
   - Age/time display

3. **Widget**: `faces_timeline_banner.dart`
   - Banner component for PeoplePage
   - Loading state management

### Database Queries Needed

```dart
// Get person's photo time span
Future<int> getPersonPhotoYearSpan(String personId);

// Get high-quality faces with timestamps
Future<List<FaceWithTimestamp>> getPersonHighQualityFaces(
  String personId,
  double minScore,
);
```

### Integration Points

1. **PeoplePage** (`people_page.dart`):

   - Add `FacesThroughTimeService` initialization
   - Add banner widget in header section
   - Trigger background processing on page load

2. **Face Quality Check**:

   - Use existing `face.score` field
   - Filter with score >= 0.85

3. **Thumbnail Generation**:
   - Use existing `getCachedFaceCrops` with `useFullFile: true`
   - Leverage existing cache system

## Performance Optimizations

### Concurrent Limits

- Max 4 thumbnail generations at once
- Sequential batch processing
- Total generation time: ~7-10 seconds for 28 faces

### Memory Management

- Load 5 thumbnails ahead (current + 4)
- Release thumbnails >5 positions behind
- Peak memory: ~15MB (5 thumbnails × 3MB)

### Background Processing

- All computation done in background
- No UI blocking
- Silent failure (just log errors)

## Edge Cases Handled

### Age-Related

- Person with DOB but some photos before age 5: Filter them out
- Person without DOB: Use all photos
- Calculating age: Use precise date math

### UI States

- Banner dismissed accidentally: Access via menu
- Slideshow interrupted: Resume from beginning
- Share cancelled: Clean up temp files

### Data Issues

- Missing thumbnails: Skip that face
- Corrupted cache: Regenerate
- Face selection fails: Don't show feature

## Success Metrics

### Primary Goals

- Users express delight and share with others
- Organic growth through shared timelines
- High completion rate (>80%)

### Tracking (Anonymous)

- Feature discovery rate
- View completion percentage
- Share button usage
- Video shares completed

## Final Specifications

### Constants

```dart
const kMinYearSpan = 7;
const kPhotosPerYear = 4;
const kMinFaceScore = 0.85;
const kMinAge = 5.0; // years
const kSlideshowInterval = 2000; // ms
const kVideoFrameDuration = 1000; // ms
const kMaxConcurrentThumbnails = 4;
const kCacheValidityDays = 365;
const kThumbnailPadding = 0.4; // 40% standard
```

### Text Strings

```dart
// Banner
"How ${person.name} grew over the years"

// Menu option
"Show face timeline"

// Age display (with DOB)
"Age ${years} years${months > 0 ? ' ${months} months' : ''}"

// Relative time (without DOB)
"${years} years ago"
"${months} months ago"
"Recently"

// Share watermark
"Created with Ente Photos"
```

## Implementation Checklist

### Core Features

- [ ] Eligibility check with age filtering
- [ ] Quantile-based face selection
- [ ] JSON caching system
- [ ] Batch thumbnail generation
- [ ] View state tracking
- [ ] Banner display logic
- [ ] Menu option for viewed timelines

### Slideshow UI

- [ ] Auto-advance timer (2 seconds)
- [ ] Tap to pause/resume
- [ ] Tap sides for navigation
- [ ] Age/time display
- [ ] Close button

### Sharing Feature

- [ ] Video generation from thumbnails
- [ ] Text overlay on frames
- [ ] Watermark addition
- [ ] System share sheet integration
- [ ] Temp file cleanup

## Questions Resolved

1. **Face selection**: Quantile approach (1st, 25th, 50th, 75th) ✓
2. **Banner behavior**: Show once until viewed ✓
3. **Controls**: Tap to pause, sides to navigate ✓
4. **Age filtering**: Exclude ≤4 years old ✓
5. **Face cropping**: Use standard padding ✓
6. **Cache duration**: 1 year ✓
7. **Loading**: No indicators, silent generation ✓
8. **Sharing**: Simple video export ✓

## Ready for Implementation

This design is now complete and ready for implementation. The MVP balances simplicity with user delight, includes viral sharing potential, and leverages existing infrastructure efficiently.
