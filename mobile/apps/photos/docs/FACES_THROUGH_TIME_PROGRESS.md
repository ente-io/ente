# Faces Through Time - Implementation Progress

## Implementation Checklist

### Phase 1: Database & Models
- [x] Create FaceTimeline model class
- [x] Create FaceTimelineEntry model class
- [x] Add getPersonFileIds query to MLDataDB
- [x] Add getPersonFacesWithScores query to MLDataDB
- [ ] Test database queries

### Phase 2: Core Service
- [x] Create FacesThroughTimeService class
- [x] Implement eligibility checking logic
- [x] Implement quantile-based face selection
- [x] Implement JSON caching mechanism
- [x] Add view state tracking with SharedPreferences

### Phase 3: Thumbnail Generation
- [ ] Integrate with existing face thumbnail cache
- [ ] Implement batch processing (4 at a time)
- [ ] Add memory management for thumbnails
- [ ] Test thumbnail generation

### Phase 4: UI Components
- [ ] Create FacesTimelineBanner widget
- [ ] Create FacesThroughTimePage (slideshow)
- [ ] Implement auto-advance timer (2 seconds)
- [ ] Add tap controls (pause/resume/navigate)
- [ ] Add age/time display logic

### Phase 5: Integration
- [ ] Create FacesTimelineReadyEvent
- [ ] Integrate with PeoplePage
- [ ] Add banner display logic
- [ ] Add menu option for viewed timelines
- [ ] Test end-to-end flow

### Phase 6: Video Generation
- [ ] Create FacesThroughTimeVideoService
- [ ] Implement FFmpeg video generation
- [ ] Add text overlays for age/time
- [ ] Add Ente watermark
- [ ] Integrate with system share sheet

### Phase 7: Testing & Polish
- [ ] Test eligibility with various photo counts
- [ ] Verify age filtering (exclude ≤4 years)
- [ ] Test video generation and sharing
- [ ] Performance optimization
- [ ] Error handling for edge cases

## Current Status
Starting implementation...

## Notes
- Following design doc: FACES_THROUGH_TIME_DESIGN_V2.md
- Following implementation guide: FACES_THROUGH_TIME_IMPLEMENTATION_COMPLETE.md