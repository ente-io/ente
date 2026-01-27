# CollectionMapDialog.tsx Function Guide

This document describes what each function in `web/apps/photos/src/components/Collections/CollectionMapDialog.tsx` does, including its purpose, inputs, outputs, and notable side effects. Functions are grouped by responsibility and follow their appearance in the file.

Type note: `Supercluster` typing is provided by the local module declaration in `web/apps/photos/src/types/supercluster.d.ts` to avoid missing-type fallbacks and keep cluster unions strongly typed.

## Map Component Loading

### `useMapComponents()`

- Purpose: Dynamically loads Leaflet React components on the client to avoid SSR issues.
- Inputs: None.
- Returns: `MapComponents | null` containing `MapContainer`, `TileLayer`, `Marker`, `useMap`.
- Side effects: Imports `react-leaflet` on the client and logs to console on failure.

### `useCurrentUser()`

- Purpose: Reads the authenticated user for favorites/visibility actions.
- Inputs: None.
- Returns: The local user object or `undefined` if unavailable.
- Side effects: None (safe memoized read).

## Map Index Utilities

### `mapIndexKey(collectionSummary)`

- Purpose: Computes the KV storage key for a collection’s map index.
- Inputs: `CollectionSummary`.
- Returns: `string` formatted as `photos-map-index-v1:{type}:{id}`.
- Side effects: None.

### `toMapIndexMeta(collectionSummary)`

- Purpose: Builds metadata used to validate cached map indexes.
- Inputs: `CollectionSummary`.
- Returns: `{ fileCount, updationTime }`.
- Side effects: None.

### `isStoredMapIndexValid(stored, meta)`

- Purpose: Guards cached index reads by verifying metadata and shape.
- Inputs: `stored: unknown`, `meta: MapIndexMeta`.
- Returns: `boolean` type guard for `MapIndexStorage`.
- Side effects: None.

### `buildMapIndexPoints(files)`

- Purpose: Extracts map points from files with geolocation and finds the newest file.
- Inputs: `EnteFile[]`.
- Returns: `{ points: MapIndexPoint[], latestFileId?: number }`.
- Side effects: Yields to the event loop every 5000 files to avoid blocking.

### `buildClusterIndex(points)`

- Purpose: Builds a `Supercluster` index for fast clustering and leaf queries.
- Inputs: `MapIndexPoint[]`.
- Returns: `Supercluster` instance with mapped `latestTimestamp` and `latestFileId` reductions.
- Type note: The map/reduce callbacks are typed via the local `MapClusterOptions` interface, and the returned value conforms to the `MapIndex` interface.
- Side effects: None.

## Map Data Hook

### `useMapData(open, collectionSummary, activeCollection, onGenericError)`

- Purpose: Loads collection files, builds/persists the spatial index, and manages thumbnails.
- Inputs:
    - `open`: dialog open state.
    - `collectionSummary`: target collection summary.
    - `activeCollection`: active collection entity (if any).
    - `onGenericError`: error handler.
- Returns: `MapDataResult` containing map state plus `removeFiles`, `updateFileVisibility`, and `queueThumbnailFetch`.
- Side effects:
    - Reads and writes to KV storage for the map index.
    - Starts a thumbnail worker that fetches thumbnails via `downloadManager`.
    - Updates local state with index, files, and thumbnails.

Internal callbacks inside `useMapData`:

- `queueThumbnailFetch(fileIDs)`: batches thumbnail requests, skips existing thumbs, and updates `thumbByFileID` as results arrive.
- `loadMapData()`: fetches files, loads or rebuilds the spatial index, computes map center, and seeds cover thumbnails.
- `removeFiles(fileIDs)`: removes files from `filesByID`, map points, and index; recomputes `latestFileId`.
- `updateFileVisibility(file, visibility)`: updates local visibility state and updates points/index when a file becomes hidden or visible again.

## Favorites Hook

### `useFavorites(open, user)`

- Purpose: Loads favorites from IndexedDB and updates favorites/visibility.
- Inputs: `open` dialog state, `user`.
- Returns: Favorite/visibility sets and handler functions.
- Side effects: Reads favorites from IndexedDB; updates favorite status via services.

Internal callbacks inside `useFavorites`:

- `loadFavorites()`: loads favorites from collections and files.
- `addToSet(set, id)` / `removeFromSet(set, id)`: immutable set helpers.
- `handleToggleFavorite(file)`: toggles favorite state and updates pending sets.
- `handleFileVisibilityUpdate(file, visibility)`: updates visibility via service and pending sets.

## Visible Photos Hook

### `useVisiblePhotos()`

- Purpose: Tracks which photos are currently visible on the map and whether the list is updating.
- Inputs: None.
- Returns: `{ visiblePhotos, setVisiblePhotos, isVisiblePhotosUpdating, setIsVisiblePhotosUpdating }`.
- Side effects: None.

## Marker Icon Builders

### `createMarkerIcon(imageSrc, size)`

- Purpose: Builds a Leaflet `DivIcon` for individual photo pins.
- Inputs: `imageSrc: string`, `size: number`.
- Returns: `DivIcon | null` (null on SSR).
- Side effects: Requires `leaflet` at runtime; generates HTML with hover styling.

### `createClusterIcon(imageSrc, size, clusterCount, interactive?)`

- Purpose: Builds a `DivIcon` for clusters with a badge and optional hover/interactive styling.
- Inputs: `imageSrc: string`, `size: number`, `clusterCount: number`, `interactive: boolean` (optional).
- Returns: `DivIcon | null` (null on SSR).
- Side effects: Requires `leaflet` at runtime; generates HTML with hover styling based on `interactive`.

## Collection Filtering Helpers

### `isFileVisible(file)`

- Purpose: Determines whether a file should be displayed (not hidden/archived).
- Inputs: `EnteFile`.
- Returns: `boolean`.
- Side effects: None.

### `getFilesForCollection(collectionSummary, activeCollection)`

- Purpose: Retrieves files for a collection, filters hidden/archived items, and removes duplicates.
- Inputs: `CollectionSummary`, `Collection | undefined`.
- Returns: `Promise<EnteFile[]>`.
- Side effects: Reads from IndexedDB via `savedCollectionFiles` and `savedCollections`.

## Main Component

### `CollectionMapDialog(props)`

- Purpose: Orchestrates map data, visible photos, favorites, and UI layout for the map dialog.
- Inputs: `CollectionMapDialogProps`.
- Returns: `ReactElement`.
- Side effects: Sets dialog z-index when the file viewer opens.

Internal callbacks inside `CollectionMapDialog`:

- `handleSetFileViewerOpen(next)`: keeps `isFileViewerOpen` in sync with viewer state.
- `handleRemotePull()`: triggers remote pull (silent) when available.
- `handleMarkTempDeleted(files)`: updates visible list and map state after deletions.
- `handleFileVisibilityUpdateWithLocalState(file, visibility)`: syncs server visibility and local map index.
- `noOpSetSelected()`: placeholder selection setter for map view.

## Layout Components

### `MapLayout(props)`

- Purpose: Lays out the sidebar and map canvas.
- Inputs: `MapLayoutProps`.
- Returns: `ReactElement`.
- Side effects: None.

### `CollectionSidebar(props)`

- Purpose: Renders collection details, cover, and file list for visible photos.
- Inputs: `CollectionSidebarProps`.
- Returns: `ReactElement`.
- Side effects: None.

Internal callbacks inside `CollectionSidebar`:

- `handleScroll(offset)`: updates scroll offset for sticky header behavior.
- `handleVisibleDateChange(date)`: updates visible date label in the header.

## Map Components

### `MapCanvas(props)`

- Purpose: Renders the Leaflet map container, tile layer, controls, and clusters.
- Inputs: `MapCanvasProps`.
- Returns: `ReactElement`.
- Side effects: None.

### `MapControls(props)`

- Purpose: Renders zoom, maps link, and attribution UI.
- Inputs: `MapControlsProps`.
- Returns: `ReactElement`.
- Side effects: Opens external map links in a new tab.

Internal callbacks inside `MapControls`:

- `handleOpenInMaps()`: opens Google Maps at the current center and zoom.
- `handleZoomIn()` / `handleZoomOut()`: controls map zoom.
- `toggleAttribution()`: toggles the attribution popup on mobile.

### `MapClusters(props)`

- Purpose: Renders cluster/point markers from `Supercluster`, manages visible photo derivation, and prefetches thumbnails.
- Inputs: `MapClustersProps`.
- Returns: `ReactElement`.
- Side effects:
    - Reads map bounds/zoom and updates visible photos.
    - Prefetches thumbnails for visible and near-visible clusters.

Internal callbacks inside `MapClusters`:

- `isClusterFeature(feature)`: type guard for cluster features.
- `updateVisibleLeaves(requestId, clusters, bounds)`: gathers in-bounds leaves, sorts by timestamp, and updates visible photos.
- `updateClusters()`: computes clusters for the current view and triggers prefetching.
- `handleClusterClick(lat, lng, expansionZoom)`: zooms into a cluster when interactive.

## Small UI Helpers

### `FloatingIconButton(props)`

- Purpose: Styled `IconButton` with consistent hover and shadow behavior.
- Inputs: `IconButtonProps`.
- Returns: `ReactElement`.
- Side effects: None.

### `CenteredBox({ children, onClose, closeLabel })`

- Purpose: Centers content for loading/error/empty states with an optional close button.
- Inputs: `children`, optional `onClose`, optional `closeLabel`.
- Returns: `ReactElement`.
- Side effects: None.

### `EmptyState({ children })`

- Purpose: Wrapper for the empty-state layout.
- Inputs: `children`.
- Returns: `ReactElement`.
- Side effects: None.

### `MapCover(props)`

- Purpose: Renders the cover hero with image, title, count, and close button.
- Inputs: `MapCoverProps`.
- Returns: `ReactElement`.
- Side effects: None.
