/**
 * PhotoSwipe sets the zIndex of its "pswp" class to 1500. We need to go higher
 * than that for our drawers and dialogs to get them to show above it.
 */
export const photoSwipeZIndex = 1500;

/**
 * The file info drawer needs to be higher than the photo viewer.
 */
export const fileInfoDrawerZIndex = photoSwipeZIndex + 1;

/**
 * Dialogs (not necessarily always) need to be higher still so to ensure they
 * are visible above the drawer in case they are shown in response to some
 * action taken in the file info drawer.
 */
export const photosDialogZIndex = 1600;
