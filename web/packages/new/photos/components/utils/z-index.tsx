/**
 * @file [Note: Custom z-indices]
 *
 * The default MUI z-index values (as of 6.4) are
 * https://mui.com/material-ui/customization/default-theme/
 *
 * zIndex: Object
 * - mobileStepper: 1000
 * - fab: 1050
 * - speedDial: 1050
 * - appBar: 1100
 * - drawer: 1200
 * - modal: 1300
 * - snackbar: 1400
 * - tooltip: 1500
 *
 * We don't customize any of those, but photoswipe, the library we use for the
 * image gallery, sets its base zIndex to a high value, so we need to tweak the
 * zIndices of components that need to appear atop it accordingly. This file
 * tries to hold those customizations.
 */

/**
 * PhotoSwipe sets the zIndex of its "pswp" class to 1500. We need to go higher
 * than that for our drawers and dialogs to get them to show above it.
 */
export const photoSwipeZ = 1500;

/**
 * The file info drawer needs to be higher than the photo viewer.
 */
export const fileInfoDrawerZ = photoSwipeZ + 1;

/**
 * Dialogs (not necessarily always) need to be higher still so to ensure they
 * are visible above the file info drawer in case they are shown in response to
 * some action taken in the file info drawer.
 */
export const aboveFileViewerContentZ = fileInfoDrawerZ + 1;
