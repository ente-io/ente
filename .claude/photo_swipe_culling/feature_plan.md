# Photo Swipe Culling Feature - Planning Document

## Design Screenshots

The following screenshots illustrate the feature design:
- `swipe_left_delete.png` - Left swipe interaction showing red overlay and trash icon for deletion
- `swipe_right_keep.png` - Right swipe interaction showing green overlay and thumbs up for keeping
- `group_carousel_view.png` - Main interface with group carousel at top and best picture badge
- `deletion_confirmation_dialog.png` - Final deletion confirmation dialog

## 1. Feature Overview

### Purpose
Transform the tedious task of removing duplicate/similar photos into an engaging, gamified experience using familiar swipe gestures inspired by dating apps like Tinder.


### Core Value Proposition
- **Efficiency**: Quick decision-making through intuitive gestures
- **Engagement**: Gamified experience reduces decision fatigue
- **Safety**: Batch processing with review capability before final deletion
- **Control**: Ability to navigate between groups and revise decisions

## 2. User Journey

### Entry Point
From Similar Images page → New icon in top-right corner (swipe/cards icon) → Opens swipe culling interface with selected images
- Icon only appears when filtered groups are available (not just when files are selected)
- Filters out single-image groups and groups with 50+ images before checking
- Carries over filtered groups from Similar Images page

### Flow
1. User selects images on Similar Images page (auto-selected duplicates)
2. Taps swipe culling icon to enter new interface
3. Reviews each image in a group via swipe gestures
4. Can navigate between groups using top carousel
5. Reviews deletion summary and confirms

## 3. UI/UX Design

### Screen Layout

#### Header
- **Left**: Back button
- **Center**: Visual progress indicator (not text "X of Y")
- **Right**: "Delete (N)" button showing total pending deletions count

#### Main Content Area
- **Swipeable Card Stack**: Current image displayed prominently
  - Shows full image without cropping (aspect ratio preserved)
  - Card size adapts to image dimensions
  - Uses full resolution image (not thumbnails) after initial load
- **Swipe Indicators**:
  - Left swipe → Red border that intensifies with swipe distance (no full overlay)
  - Right swipe → Green border that intensifies with swipe distance (no full overlay)
  - Visual feedback: Only colored border, no full image overlay

#### Group Navigation (Top Carousel)
- Horizontal scrollable list of image groups
- **Visual Design**:
  - **Current group**: Two thumbnails stacked with slight rotation (like cards)
  - **Other groups**: Single thumbnail of first image
  - **Size difference**: Current group slightly larger than others
  - **Selection indicator**: Non-selected groups shown with reduced opacity (not border highlight)
  - **Completion badges**: Small badge showing deletion count when complete (if > 0)
- **Interaction Model**:
  - **Single tap on current group**: Show summary popup
  - **Single tap on other group**: Navigate to that group
  - **Long press**: Show popup summary with:
    - Images kept vs deleted count
    - Visual preview of decisions
    - "Undo all" action for that group
    - Storage to be freed from this group

#### Bottom Action Bar
- Positioned slightly above bottom edge
- **Container Design**: Rounded container (borderRadius: 8) with subtle background
- **Left**: Delete button (red) - quick delete current image
- **Center**: Undo button with circular arrow icon - revert last action
- **Right**: Keep button (green) - quick keep current image

### Interaction Patterns

#### Swipe Gestures
- **Right Swipe**: Mark image as "keep" (green indicator)
- **Left Swipe**: Mark image for deletion (red indicator)
- **Swipe Threshold**: ~30% of screen width to trigger action
- **Snap Back**: If swipe incomplete, card returns to center

#### Button Actions
- **Bottom Delete**: Alternative to left swipe
- **Bottom Keep**: Alternative to right swipe
- **Undo**: Reverts last swipe action within current group only
- **Group Undo**: Available via long-press on group in carousel (shows popup summary)
- **Confirm**: Opens deletion summary dialog

#### Auto-Advance Flow (Group Completion)
**Minimal Celebration Approach**: Ultra-quick, non-intrusive transition
1. **Duration**: Maximum 0.25-0.4s (half current time)
2. **Animation**: Light sprinkle effect or simple checkmark fade
3. **No text**: No "Group complete" message
4. **Smooth Transition**: Quick cross-fade to next group's first photo
5. **Non-blocking**: Animation doesn't prevent immediate interaction

**Alternative Approaches Considered**:
- Streak celebration with momentum carry-forward
- Level-up gaming style transitions
- Stories-style progress segments
- Swipe-through summary card

#### Special Cases
- **"Best Picture" Badge**: Currently shows first image in group (v1 implementation)
  - Future: Algorithm based on quality metrics, resolution, and filename patterns
- **Last Card in Group**: Auto-advances with celebration animation as described above

## 4. Feature Requirements

### Functional Requirements

#### Core Features
- [ ] Display images from selected similar groups in swipeable card interface
- [ ] Filter out single-image groups and groups with 50+ images
- [ ] Support swipe left (delete) and swipe right (keep) gestures
- [ ] Visual feedback during swipe (color overlays, icons)
- [ ] Track decisions per image (keep/delete/undecided)
- [ ] Group navigation carousel at top with image count badges
- [ ] Undo functionality for last action within current group
- [ ] Group-level undo via long-press popup
- [ ] Batch deletion and symlinking using existing `_deleteFilesLogic` from similar images page
- [ ] Progress tracking per group
- [ ] Auto-advance with minimal celebration animation between groups

#### Data Management
- [ ] Maintain decision state for each image
- [ ] Keep state in memory during session (no persistence in v1)
- [ ] Track full decision history for final deletion
- [ ] Track group-specific history for undo functionality
- [ ] Calculate and display deletion count
- [ ] Calculate storage to be freed

#### Navigation
- [ ] Entry from Similar Images page with selected files
- [ ] Exit handling (prompt if unsaved changes)
- [ ] Group switching via carousel
- [ ] Return to Similar Images after completion

### Non-Functional Requirements

#### Performance
- **Critical**: Smooth 60fps swipe animations (top priority)
- Display thumbnails first, then load full resolution images
- Preload next 2-3 images for instant display
- Lazy load group thumbnails in carousel
- Handle groups with 100+ images efficiently
- Memory efficiency through smart image recycling

#### User Experience
- Haptic feedback on swipe completion (if available)
- Clear visual states (undecided/keep/delete)
- Responsive to quick successive swipes
- Accessibility support for screen readers

## 5. Technical Architecture

### State Management
```dart
class SwipeCullingState {
  List<SimilarFiles> groups;
  int currentGroupIndex;
  int currentImageIndex;
  Map<EnteFile, SwipeDecision> decisions; // Global decisions
  Map<int, List<SwipeAction>> groupHistories; // Per-group undo history
  List<SwipeAction> fullHistory; // Complete history for final deletion
}

enum SwipeDecision { keep, delete, undecided }

class SwipeAction {
  EnteFile file;
  SwipeDecision decision;
  DateTime timestamp;
  int groupIndex;
}
```

### Key Components

#### SwipeCullingPage
- Main page widget managing overall state
- Handles navigation between groups
- Manages confirmation and deletion flow

#### SwipeablePhotoCard
- Individual card widget with swipe detection
- Handles gesture recognition and animation
- Renders image with overlay effects

#### GroupCarousel
- Horizontal scrollable group selector
- Shows thumbnails and progress badges
- Handles group switching

#### SwipeActionBar
- Bottom control buttons
- Triggers same actions as swipe gestures
- Manages undo stack

### Data Flow
1. Receive selected `List<SimilarFiles>` from Similar Images page
2. Filter out single-image groups and groups with 50+ images
3. Initialize decision map with all images as "undecided"
4. Update decisions based on user swipes
5. On confirm, filter images marked for deletion
6. Execute deletion using existing `_deleteFilesLogic` from Similar Images
   - Includes symlink creation for collection preservation
   - Handles bulk deletion with progress indicators
   - Shows congratulations dialog for 100+ deletions

## 6. Implementation Phases

### Phase 1: Core Swipe Interface (MVP)
- Implement flutter_card_swiper for smooth animations
- Left/right swipe detection with visual feedback
- Color overlays and icons during swipe
- Single group support initially
- Basic confirm/delete flow
- Thumbnail-first image loading strategy

### Phase 2: Multi-Group Navigation
- Group carousel implementation
- Group switching logic
- Progress tracking per group
- Auto-advance between groups

### Phase 3: Polish & Optimization
- Smooth animations and transitions
- Haptic feedback
- Image preloading
- Performance optimization
- Undo functionality

### Phase 4: Advanced Features (Future)
- AI-powered "Best Picture" suggestions
- Bulk actions (delete all in group)
- Swipe sensitivity settings
- Statistics (photos reviewed, space saved)

## 7. Detailed Component Specifications

### SwipeablePhotoCard Widget
```dart
class SwipeablePhotoCard extends StatefulWidget {
  final EnteFile file;
  final VoidCallback onSwipeLeft;  // Delete
  final VoidCallback onSwipeRight; // Keep
  final bool showBestPictureBadge;
}
```

**Behavior:**
- Displays image with proper aspect ratio
- Tracks finger position during drag
- Calculates swipe velocity and direction
- Shows overlay based on swipe direction
- Animates card exit on decision
- Returns to center if swipe incomplete

### GroupCarousel Widget
```dart
class GroupCarousel extends StatelessWidget {
  final List<SimilarFiles> groups;
  final int currentGroupIndex;
  final Function(int) onGroupSelected;
  final Map<SimilarFiles, GroupProgress> progressMap;
}
```

**Features:**
- 2x2 grid thumbnail for each group
- Clean thumbnails for unreviewd groups (no badges)
- **Red badge showing deletion count** for completed groups (only if > 0)
- Green checkmark for groups with all images kept
- Highlight current group with subtle border/glow
- Smooth scroll to selected group
- Long-press triggers popup with grid view and overlay indicators

### Confirmation Dialogs

#### Contextual Confirmations
1. **All-in-Group Deletion** (Shows immediately when user marks all images in a group for deletion):
   - "Delete all images in this group?"
   - "You've marked all X images for deletion. This will remove the entire group."
   - Options: "Delete All" / "Review Again"

2. **Final Batch Deletion** (When user taps Confirm button):
   - "Delete images - Are you sure you want to delete all the images you swiped left on?"
   - Shows total count and storage to be freed
   - Options: "Delete" / "Cancel"

3. **No Additional Confirmation** needed when:
   - Some (but not all) images in a group are marked for deletion
   - User is just navigating between groups
   - Using undo actions

## 8. Edge Cases & Considerations

### Edge Cases
- Single image groups: Not displayed in UI, filtered out completely
- User exits without confirming: Changes lost (no persistence in v1)
- Network/storage issues: Handled by existing bulk delete logic
- Large groups (50+ images): Hidden from UI in v1, not displayed
- Videos: Not applicable (Similar Images only handles photos)
- All images in group marked for deletion: Show immediate confirmation dialog

### Security & Privacy
- Maintain E2E encryption throughout
- No server-side processing of decisions
- Local-only gesture data

### Accessibility
- Alternative buttons for all swipe actions
- Screen reader support with clear descriptions
- Keyboard navigation support
- High contrast mode compatibility

## 9. Success Metrics

### User Engagement
- Time to review X images (target: <1 second per image)
- Completion rate (% users who finish review)
- Undo usage rate (indicates decision confidence)

### Feature Effectiveness
- Storage space reclaimed
- Number of duplicates removed
- User retention after using feature

## 10. Resolved Design Decisions

1. **Group Completion Behavior**: ✅ Auto-advance with minimal celebration animation
2. **Decision Persistence**: ✅ No persistence in v1 (add in future version)
3. **Best Picture Algorithm**: ✅ Use first image in group for v1
4. **Undo Scope**: ✅ Per-group undo history + group-level undo via long-press
5. **Animation Priority**: ✅ Smooth animations are critical, use flutter_card_swiper
6. **Single Image Groups**: ✅ Filter out completely, not shown in UI
7. **Large Groups**: ✅ Hide groups with 50+ images in v1
8. **Videos**: ✅ Not applicable (Similar Images is photos-only)
9. **Entry Point**: ✅ Icon only visible when images selected
10. **Deletion Logic**: ✅ Reuse existing `_deleteFilesLogic` with symlinks

## 11. Final Design Specifications

### Count Display Strategy
**Main Swipe Interface:**
- Header shows "X of Y" for current group only (subtle, non-intrusive)
- Optional: Progress dots below photo showing keep/delete pattern

**Carousel Groups:**
- Unreviewd: Clean thumbnails, no badges
- Current: Subtle highlight/border
- Completed: Red badge with deletion count (only if > 0)
- Alternative: Green checkmark if all kept

### Group Summary Popup (Long-press on carousel)
**Design**: Grid view with overlay indicators
- Shows all thumbnails in a grid layout
- Deleted images have red overlay with trash icon
- Kept images shown normally
- Bottom actions:
  - "Undo All" button (secondary style)
  - "Delete These" button (critical style, for group-specific deletion)
- Shows storage to be freed at top

### Completion Flow
**All Groups Reviewed Dialog:**
- Appears after last group is completed
- Content:
  - "All groups reviewed!"
  - "X files marked for deletion"
  - "Y MB will be freed"
- Actions:
  - Primary: "Delete Files" button
  - Secondary: "Review Again" button
- After deletion: Returns to Similar Images page

## 12. Dependencies

### Existing Components to Reuse
- `SimilarFiles` data model
- `EnteFile` model
- Deletion utilities with symlink support
- Image loading/caching system
- `ThumbnailWidget` for previews

### New Package Requirements
- **flutter_card_swiper** (Recommended: Best performance, active maintenance, undo support)
  - Alternative: `appinio_swiper` for maximum memory efficiency
- Advanced animations (`flutter_animate`)
- Haptic feedback (`haptic_feedback`)
- Image optimization (`cached_network_image` with `flutter_cache_manager`)

## 13. Risk Assessment

### Technical Risks
- **Performance**: Smooth animations with high-res images
- **Memory**: Managing multiple images in memory
- **State Complexity**: Tracking decisions across multiple groups

### Mitigation Strategies
- Display thumbnails first, lazy load full resolution
- Use `flutter_card_swiper` with proper image caching
- Implement aggressive image recycling
- Simple, flat state structure with clear update patterns
- Preload strategically (next 2-3 images only)
- Consider WebP format for image compression

## 14. Testing Strategy

### Unit Tests
- Decision state management
- Undo/redo logic
- Group navigation logic

### Widget Tests
- Swipe gesture recognition
- Animation states
- Button interactions

### Integration Tests
- Full flow from Similar Images to deletion
- State persistence
- Error handling

### User Testing
- A/B test auto-advance vs manual navigation
- Test swipe sensitivity settings
- Gather feedback on animation speed

## 15. Documentation Needs

### User Documentation
- Tutorial on first use
- Gesture guide
- FAQ section

### Developer Documentation
- State management architecture
- Component interaction diagrams
- Animation timing specifications

## 16. Future Enhancements

### V2 Features (Next Release)
- **Decision Persistence**: Save swipe decisions across sessions
- **Smart Best Picture Algorithm**:
  - Technical quality metrics (resolution, blur, exposure)
  - Filename pattern analysis (avoid "Copy" versions)
  - ML-based composition analysis
- **Batch Group Operations**: "Delete all except first" quick action
- **Advanced Statistics**: Photos reviewed, space saved, time spent

### V3 Features (Future)
- Advanced filters (by date, size, etc.)
- ML-powered quality detection with learning
- Face recognition priority
- Auto-grouping by events
- Collaborative culling (family shared albums)
- Cloud backup of decision history
- Swipe sensitivity customization

## 17. Implementation Plan

### File Structure
```
mobile/apps/photos/lib/ui/
├── pages/
│   └── library_culling/
│       ├── swipe_culling_page.dart
│       ├── widgets/
│       │   ├── swipeable_photo_card.dart
│       │   ├── group_carousel.dart
│       │   ├── swipe_action_bar.dart
│       │   └── group_summary_popup.dart
│       └── models/
│           └── swipe_culling_state.dart
```

### State Management
- Use `StatefulWidget` with `setState` for main page state
- Keep state simple and isolated to this feature
- No new dependencies required

### Navigation & Data Passing
- Pass selected `List<SimilarFiles>` via constructor from Similar Images page
- Return result (deleted count) via `Navigator.pop(result)`

### Key Implementation Steps

#### Step 1: Create Base Structure
1. Create folder structure under `lib/ui/pages/library_culling/`
2. Create `SwipeCullingPage` StatefulWidget
3. Define `SwipeCullingState` model class
4. Set up basic navigation from Similar Images page

#### Step 2: Add Entry Point Icon
1. In `similar_images_page.dart`, add icon to AppBar actions
2. Show icon only when `selectedFiles.isNotEmpty`
3. Icon navigates to `SwipeCullingPage` with selected groups
4. Use `Icons.view_carousel_rounded` icon

#### Step 3: Implement Core Swipe Interface
1. Add `flutter_card_swiper` to pubspec.yaml
2. Create `SwipeablePhotoCard` widget
3. Implement swipe detection and visual feedback
4. Track decisions in state map
5. Test with single group first

#### Step 4: Build UI Components
1. **Header**: Back button, "X of Y" counter, Confirm button
2. **GroupCarousel**: Horizontal list with thumbnails and badges
3. **SwipeActionBar**: Delete/Undo/Keep buttons
4. **Swipe overlays**: Red/green borders with icons

#### Step 5: Implement Group Navigation
1. Add carousel widget with tap/long-press handlers
2. Implement group switching logic
3. Add progress tracking per group
4. Implement auto-advance with minimal celebration using Ente color scheme

#### Step 6: Add Popup Interactions
1. Create `GroupSummaryPopup` for long-press
2. Show grid with overlay indicators
3. Add "Undo All" and "Delete These" actions
4. Calculate and display storage savings

#### Step 7: Duplicate & Adapt Deletion Logic
1. Copy `_deleteFilesLogic` from `similar_images_page.dart`
2. Adapt for swipe culling context
3. Maintain symlink creation logic
4. Add progress indicators

#### Step 8: Implement Completion Flow
1. Detect when all groups reviewed
2. Show "All groups reviewed!" dialog
3. Display deletion summary (count + storage)
4. Execute batch deletion on confirmation
5. Navigate back to Similar Images page

#### Step 9: Add Localization
1. Add strings to `/mobile/apps/photos/lib/l10n/intl_en.arb`:
   ```json
   "swipeToReview": "Swipe to Review",
   "imageXOfY": "{current} of {total}",
   "allGroupsReviewed": "All groups reviewed!",
   "filesMarkedForDeletion": "{count} files marked for deletion",
   "storageToBeFreed": "{size} will be freed",
   "deleteFiles": "Delete Files",
   "reviewAgain": "Review Again",
   "deleteThese": "Delete These",
   "undoAll": "Undo All",
   "groupComplete": "Group complete",
   "deleteAllInGroup": "Delete all images in this group?",
   "allImagesMarkedForDeletion": "You've marked all {count} images for deletion"
   ```
2. Use via `AppLocalizations.of(context).stringKey`

#### Step 10: Handle Edge Cases
1. Filter out single-image groups
2. Filter out groups with 50+ images
3. Implement confirmation for all-in-group deletion
4. Handle exit without saving (show warning dialog)

#### Step 11: Performance Optimization
1. Use `ThumbnailWidget` for initial display
2. Lazy load full resolution images
3. Preload next 2-3 images
4. Implement image recycling
5. Test with large datasets

#### Step 12: Testing
1. Unit tests for state management logic
2. Widget tests for swipe detection
3. Integration test for full flow
4. Manual testing on physical devices
5. Performance profiling

### Development Order
1. **Day 1**: Steps 1-4 (Base structure + core swipe)
2. **Day 2**: Steps 5-6 (Group navigation + popups)
3. **Day 3**: Steps 7-8 (Deletion logic + completion)
4. **Day 4**: Steps 9-10 (Localization + edge cases)
5. **Day 5**: Steps 11-12 (Optimization + testing)

### Code Snippets

#### Navigation from Similar Images
```dart
// In similar_images_page.dart AppBar actions
if (selectedFiles.isNotEmpty)
  IconButton(
    icon: Icon(Icons.view_carousel_rounded),
    onPressed: () async {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SwipeCullingPage(
            similarFiles: selectedFiles,
          ),
        ),
      );
      if (result != null && result > 0) {
        // Refresh page after deletion
        _loadSimilarFiles();
      }
    },
  ),
```

#### Basic State Structure
```dart
class SwipeCullingPage extends StatefulWidget {
  final List<SimilarFiles> similarFiles;
  
  const SwipeCullingPage({
    Key? key,
    required this.similarFiles,
  }) : super(key: key);
  
  @override
  State<SwipeCullingPage> createState() => _SwipeCullingPageState();
}

class _SwipeCullingPageState extends State<SwipeCullingPage> {
  late List<SimilarFiles> groups;
  int currentGroupIndex = 0;
  int currentImageIndex = 0;
  Map<EnteFile, SwipeDecision> decisions = {};
  Map<int, List<SwipeAction>> groupHistories = {};
  
  @override
  void initState() {
    super.initState();
    // Filter groups (no singles, no 50+)
    groups = widget.similarFiles
        .where((g) => g.files.length > 1 && g.files.length < 50)
        .toList();
    // Initialize all as undecided
    for (final group in groups) {
      for (final file in group.files) {
        decisions[file] = SwipeDecision.undecided;
      }
    }
  }
  
  // ... rest of implementation
}
```

### Testing Checklist
- [ ] Swipe gestures work smoothly
- [ ] Visual feedback appears correctly
- [ ] Group navigation works
- [ ] Undo functionality works within groups
- [ ] Long-press popup displays correctly
- [ ] Deletion logic preserves symlinks (same as similar_images_page.dart)
- [ ] Completion flow shows summary
- [ ] All edge cases handled
- [ ] Performance acceptable with many images
- [ ] Localization works correctly
- [ ] No analytics or tracking code present

### Key Implementation Notes
1. **Icon**: Use `Icons.view_carousel_rounded` for entry point
2. **Header Button**: Shows "Delete (N)" not "Confirm (N)"
3. **Celebration Animation**: Simple, minimal, using Ente colorScheme
4. **Deletion Logic**: Exact copy from `_deleteFilesLogic` in similar_images_page.dart
5. **No Analytics**: Never add any tracking or telemetry code
