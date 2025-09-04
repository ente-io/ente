# Flicker Fix Attempts - Post-Swipe Animation Issue

This document tracks all attempted solutions to fix the slight flicker that occurs right after swiping an image in the photo swipe culling interface.

## Problem Description

After swiping an image (left or right), there's a brief flicker that occurs at the end of the swipe animation. The animation itself is smooth, but there's a visual glitch right as it completes and the next card comes into view.

## Attempted Solutions

### Attempt 1: Stabilize CardSwiper Key (FAILED)

**Theory**: The flicker was caused by the CardSwiper widget rebuilding due to a changing key that included `currentImageIndex`.

**Changes Made**:
```dart
// Before
key: ValueKey('swiper_${currentGroupIndex}_$currentImageIndex'),

// After  
key: ValueKey('swiper_$currentGroupIndex'),
```

**Result**: No improvement - flicker still present.

**Why it failed**: The key wasn't the root cause of the flicker issue.

### Attempt 2: Minimize setState and Separate Data Updates (FAILED - CAUSED REGRESSION)

**Theory**: The flicker was caused by frequent setState calls rebuilding the entire CardSwiper widget. By updating data outside setState and only triggering minimal UI updates, the CardSwiper could maintain its internal animation state.

**Changes Made**:
```dart
void _handleSwipeDecision(SwipeDecision decision) {
  // ... existing code ...

  // Update decisions without setState to avoid rebuilding CardSwiper
  decisions[file] = decision;
  
  // ... update other data ...
  
  // Only trigger setState for UI elements that need to update (not CardSwiper)
  setState(() {
    // This minimal setState updates progress dots, file info, etc.
  });
}
```

**Result**: Made the issue worse and caused regressions in functionality.

**Why it failed**: The approach broke the normal Flutter state management flow and caused UI inconsistencies.

## Current Status

Both attempts have been reverted. The flicker issue persists and needs a different approach.

## Potential Next Steps for Investigation

1. **Examine flutter_card_swiper internals**: The issue might be within the CardSwiper package itself
2. **Check image loading/caching**: The flicker might be related to image transitions between cards
3. **Animation timing**: Look at the coordination between swipe animation completion and next card display
4. **Widget tree analysis**: Use Flutter Inspector to see exactly what's rebuilding during the flicker
5. **Alternative swipe packages**: Consider if flutter_card_swiper has known issues with this behavior

## Code Location

The main swipe implementation is in:
- `/lib/ui/pages/library_culling/swipe_culling_page.dart` (lines ~615-690 for CardSwiper widget)
- `/lib/ui/pages/library_culling/widgets/swipeable_photo_card.dart` (individual card implementation)

## Test Scenario

To reproduce the flicker:
1. Open swipe culling interface
2. Swipe any image (left or right)  
3. Observe the brief flicker at the end of the swipe animation as the next card settles into place