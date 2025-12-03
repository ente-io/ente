import { keyframes } from "@emotion/react";
import AddIcon from "@mui/icons-material/Add";
import CloseIcon from "@mui/icons-material/Close";
import NavigationIcon from "@mui/icons-material/Navigation";
import RemoveIcon from "@mui/icons-material/Remove";
import {
    Box,
    Dialog,
    DialogContent,
    IconButton,
    Skeleton,
    Stack,
    styled,
    Typography,
    type IconButtonProps,
} from "@mui/material";
import { ensureLocalUser } from "ente-accounts/services/user";
import { ActivityIndicator } from "ente-base/components/mui/ActivityIndicator";
import type { ModalVisibilityProps } from "ente-base/components/utils/modal";
import { useBaseContext } from "ente-base/context";
import { FileViewer } from "ente-gallery/components/viewer/FileViewer";
import { downloadManager } from "ente-gallery/services/download";
import { uniqueFilesByID } from "ente-gallery/utils/file";
import { type Collection } from "ente-media/collection";
import { type EnteFile } from "ente-media/file";
import {
    fileCreationTime,
    fileFileName,
    fileLocation,
    ItemVisibility,
} from "ente-media/file-metadata";
import {
    addToFavoritesCollection,
    removeFromFavoritesCollection,
} from "ente-new/photos/services/collection";
import { type CollectionSummary } from "ente-new/photos/services/collection-summary";
import { updateFilesVisibility } from "ente-new/photos/services/file";
import {
    savedCollectionFiles,
    savedCollections,
} from "ente-new/photos/services/photos-fdb";
import { t } from "i18next";
import "leaflet/dist/leaflet.css";
import React, {
    useCallback,
    useEffect,
    useMemo,
    useRef,
    useState,
} from "react";
import {
    calculateOptimalZoom,
    createIcon,
    getMapCenter,
} from "../TripLayout/mapHelpers";
import type { JourneyPoint } from "../TripLayout/types";
import { generateNeededThumbnails } from "../TripLayout/utils/dataProcessing";

// ============================================================================
// Types
// ============================================================================

/**
 * Type definitions for the CollectionMapDialog component and its dependencies
 */

interface MapComponents {
    MapContainer: typeof import("react-leaflet").MapContainer;
    TileLayer: typeof import("react-leaflet").TileLayer;
    Marker: typeof import("react-leaflet").Marker;
    useMap: typeof import("react-leaflet").useMap;
    MarkerClusterGroup: typeof import("react-leaflet-cluster").default;
}

interface CollectionMapDialogProps extends ModalVisibilityProps {
    collectionSummary: CollectionSummary;
    activeCollection: Collection;
}

interface PhotoGroup {
    dateLabel: string;
    photos: JourneyPoint[];
}

interface MapDataState {
    mapCenter: [number, number] | null;
    mapPhotos: JourneyPoint[];
    filesByID: Map<number, EnteFile>;
    thumbByFileID: Map<number, string>;
    isLoading: boolean;
    error: string | null;
}

interface FileViewerState {
    open: boolean;
    currentIndex: number;
    files: EnteFile[];
}

interface FavoritesState {
    favoriteFileIDs: Set<number>;
    pendingFavoriteUpdates: Set<number>;
    pendingVisibilityUpdates: Set<number>;
}

// ============================================================================
// Custom Hooks
// ============================================================================

/**
 * Dynamically loads map-related React components (Leaflet) to avoid SSR issues
 * Responsibility: Lazy load map dependencies only when needed
 */
function useMapComponents() {
    const [mapComponents, setMapComponents] = useState<MapComponents | null>(
        null,
    );

    useEffect(() => {
        void Promise.all([
            import("react-leaflet"),
            import("react-leaflet-cluster"),
        ])
            .then(([leaflet, cluster]) =>
                setMapComponents({
                    MapContainer: leaflet.MapContainer,
                    TileLayer: leaflet.TileLayer,
                    Marker: leaflet.Marker,
                    useMap: leaflet.useMap,
                    MarkerClusterGroup: cluster.default,
                }),
            )
            .catch((e: unknown) => {
                console.error("Failed to load map components", e);
            });
    }, []);

    return mapComponents;
}

/**
 * Retrieves the current authenticated user
 * Responsibility: Provide user context for favorite/visibility operations
 */
function useCurrentUser() {
    return useMemo(() => {
        try {
            return ensureLocalUser();
        } catch {
            return undefined;
        }
    }, []);
}

/**
 * Animates a counter value with smooth easing
 * Responsibility: Provide smooth number transitions for UI counters
 */
function useAnimatedCounter(targetValue: number, duration = 500) {
    const [displayValue, setDisplayValue] = useState(targetValue);
    const previousValue = useRef(targetValue);
    const animationFrameRef = useRef<number | null>(null);

    useEffect(() => {
        const startValue = previousValue.current;
        const difference = targetValue - startValue;

        if (difference === 0) return;

        const startTime = performance.now();

        const animate = (currentTime: number) => {
            const elapsed = currentTime - startTime;
            const progress = Math.min(elapsed / duration, 1);

            // Ease out cubic for smooth deceleration
            const easeOut = 1 - Math.pow(1 - progress, 3);
            const currentValue = Math.round(startValue + difference * easeOut);

            setDisplayValue(currentValue);

            if (progress < 1) {
                animationFrameRef.current = requestAnimationFrame(animate);
            } else {
                previousValue.current = targetValue;
                animationFrameRef.current = null;
            }
        };

        animationFrameRef.current = requestAnimationFrame(animate);

        // Cleanup: cancel animation frame on unmount or when dependencies change
        return () => {
            if (animationFrameRef.current !== null) {
                cancelAnimationFrame(animationFrameRef.current);
            }
        };
    }, [targetValue, duration]);

    return displayValue;
}

/**
 * Loads and manages map data including photos, locations, and thumbnails
 * Responsibility: Fetch collection files, extract locations, generate thumbnails
 */
function useMapData(
    open: boolean,
    activeCollection: Collection,
    onGenericError: (e: unknown) => void,
): MapDataState {
    const [state, setState] = useState<MapDataState>({
        mapCenter: null,
        mapPhotos: [],
        filesByID: new Map(),
        thumbByFileID: new Map(),
        isLoading: false,
        error: null,
    });

    const loadAllThumbs = useCallback(
        async (points: JourneyPoint[], files: EnteFile[]) => {
            // Build a Map for O(1) file lookup instead of O(n) find
            const filesById = new Map(files.map((f) => [f.id, f]));

            const entries = await Promise.all(
                points.map(async (p) => {
                    if (p.image) return [p.fileId, p.image] as const;
                    const file = filesById.get(p.fileId);
                    if (!file) return [p.fileId, undefined] as const;
                    try {
                        const thumb =
                            await downloadManager.renderableThumbnailURL(file);
                        return [p.fileId, thumb] as const;
                    } catch {
                        return [p.fileId, undefined] as const;
                    }
                }),
            );

            setState((prev) => ({
                ...prev,
                thumbByFileID: new Map(
                    entries.filter(([, t]) => t !== undefined) as [
                        number,
                        string,
                    ][],
                ),
            }));
        },
        [],
    );

    useEffect(() => {
        if (!open) return;

        const loadMapData = async () => {
            setState((prev) => ({ ...prev, isLoading: true, error: null }));

            try {
                const files = await getFilesForCollection(activeCollection);
                const locationPoints = extractLocationPoints(files);

                if (locationPoints.length) {
                    const sortedPoints = sortPhotosByTimestamp(locationPoints);

                    const { thumbnailUpdates } = await generateNeededThumbnails(
                        { photoClusters: [sortedPoints], files },
                    );

                    const pointsWithThumbs = sortedPoints.map((point) => {
                        const thumb = thumbnailUpdates.get(point.fileId);
                        return thumb ? { ...point, image: thumb } : point;
                    });

                    setState({
                        filesByID: new Map(
                            files.map((file) => [file.id, file]),
                        ),
                        mapCenter: getMapCenter([], pointsWithThumbs),
                        mapPhotos: pointsWithThumbs,
                        thumbByFileID: new Map(),
                        isLoading: false,
                        error: null,
                    });

                    void loadAllThumbs(pointsWithThumbs, files);
                }

                return;
            } catch (e) {
                setState((prev) => ({
                    ...prev,
                    isLoading: false,
                    error: t("something_went_wrong"),
                }));
                onGenericError(e);
            }
        };

        void loadMapData();
    }, [open, activeCollection, onGenericError, loadAllThumbs]);

    return state;
}

/**
 * Manages favorite files state and handles favorite/visibility updates
 * Responsibility: Load user's favorites, toggle favorite status, update file visibility
 */
function useFavorites(
    open: boolean,
    user: ReturnType<typeof useCurrentUser>,
): FavoritesState & {
    handleToggleFavorite: (file: EnteFile) => Promise<void>;
    handleFileVisibilityUpdate: (
        file: EnteFile,
        visibility: ItemVisibility,
    ) => Promise<void>;
} {
    const [favoriteFileIDs, setFavoriteFileIDs] = useState<Set<number>>(
        new Set(),
    );
    const [pendingFavoriteUpdates, setPendingFavoriteUpdates] = useState<
        Set<number>
    >(new Set());
    const [pendingVisibilityUpdates, setPendingVisibilityUpdates] = useState<
        Set<number>
    >(new Set());

    useEffect(() => {
        if (!open || !user) return;

        const loadFavorites = async () => {
            const collections = await savedCollections();
            const collectionFiles = await savedCollectionFiles();

            for (const collection of collections) {
                if (
                    collection.type === "favorites" &&
                    collection.owner.id === user.id
                ) {
                    const favoriteIDs = new Set(
                        collectionFiles
                            .filter((f) => f.collectionID === collection.id)
                            .map((f) => f.id),
                    );
                    setFavoriteFileIDs(favoriteIDs);
                    break;
                }
            }
        };

        void loadFavorites();
    }, [open, user]);

    // Helper to add/remove from Set immutably - avoids recreating Set when unnecessary
    const addToSet = useCallback(
        (set: Set<number>, id: number) => {
            if (set.has(id)) return set;
            const next = new Set(set);
            next.add(id);
            return next;
        },
        [],
    );

    const removeFromSet = useCallback(
        (set: Set<number>, id: number) => {
            if (!set.has(id)) return set;
            const next = new Set(set);
            next.delete(id);
            return next;
        },
        [],
    );

    const handleToggleFavorite = useCallback(
        async (file: EnteFile) => {
            if (!user) return;
            const fileID = file.id;

            // Check favorite status at call time to avoid stale closure
            const isFavorite = favoriteFileIDs.has(fileID);

            setPendingFavoriteUpdates((prev) => addToSet(prev, fileID));
            try {
                const action = isFavorite
                    ? removeFromFavoritesCollection
                    : addToFavoritesCollection;
                await action([file]);
                setFavoriteFileIDs((prev) =>
                    isFavorite
                        ? removeFromSet(prev, fileID)
                        : addToSet(prev, fileID),
                );
            } finally {
                setPendingFavoriteUpdates((prev) => removeFromSet(prev, fileID));
            }
        },
        [user, favoriteFileIDs, addToSet, removeFromSet],
    );

    const handleFileVisibilityUpdate = useCallback(
        async (file: EnteFile, visibility: ItemVisibility) => {
            const fileID = file.id;
            setPendingVisibilityUpdates((prev) => addToSet(prev, fileID));
            try {
                await updateFilesVisibility([file], visibility);
            } finally {
                setPendingVisibilityUpdates((prev) =>
                    removeFromSet(prev, fileID),
                );
            }
        },
        [addToSet, removeFromSet],
    );

    return {
        favoriteFileIDs,
        pendingFavoriteUpdates,
        pendingVisibilityUpdates,
        handleToggleFavorite,
        handleFileVisibilityUpdate,
    };
}

/**
 * Manages file viewer state including open/close and file navigation
 * Responsibility: Handle photo clicks, prepare sorted file list for viewer, manage viewer open state
 */
function useFileViewer(
    filesByID: Map<number, EnteFile>,
    visiblePhotos: JourneyPoint[],
): FileViewerState & {
    handlePhotoClick: (fileId: number) => void;
    handleClose: () => void;
} {
    const [state, setState] = useState<FileViewerState>({
        open: false,
        currentIndex: 0,
        files: [],
    });

    const handlePhotoClick = useCallback(
        (fileId: number) => {
            // Only show files that are currently visible on the map/sidebar
            // Note: visiblePhotos are already sorted by timestamp
            const visibleFiles = visiblePhotos
                .map((p) => filesByID.get(p.fileId))
                .filter((f): f is EnteFile => f !== undefined);

            // Open the viewer on the clicked file if it exists in the visible list
            const clickedIndex = visibleFiles.findIndex((f) => f.id === fileId);

            if (clickedIndex !== -1 && visibleFiles.length > 0) {
                setState({
                    files: visibleFiles,
                    currentIndex: clickedIndex,
                    open: true,
                });
            }
        },
        [filesByID, visiblePhotos],
    );

    // Close handler simply hides the viewer while keeping the file list cached
    const handleClose = useCallback(() => {
        setState((prev) => ({ ...prev, open: false }));
    }, []);

    return { ...state, handlePhotoClick, handleClose };
}

/**
 * Manages the lifecycle of the currently visible journey photos and their derived metadata.
 *
 * Tracks the ordered list of visible photos, exposes a setter to update them, and maintains a
 * monotonically increasing “wave” counter that changes whenever the visible photos change—allowing
 * consumers to detect visibility updates without diffing arrays manually.
 *
 * Additionally memoizes:
 * - `photoGroups`: photos bucketed by formatted date label for grouped rendering.
 * - `visiblePhotoOrder`: map of photo file IDs to their position in the visible array for O(1) lookups.
 *
 * @returns An object containing the visible photos array, setter, wave counter, grouped photos, and ordering map.
 */
function useVisiblePhotos() {
    const [visiblePhotos, setVisiblePhotos] = useState<JourneyPoint[]>([]);
    const [visiblePhotosWave, setVisiblePhotosWave] = useState(0);

    useEffect(() => {
        setVisiblePhotosWave((wave) => wave + 1);
    }, [visiblePhotos]);

    const photoGroups = useMemo<PhotoGroup[]>(() => {
        const groups = new Map<string, JourneyPoint[]>();
        visiblePhotos.forEach((p) => {
            const dateLabel = formatDateLabel(p.timestamp);
            if (!groups.has(dateLabel)) {
                groups.set(dateLabel, []);
            }
            groups.get(dateLabel)!.push(p);
        });
        return Array.from(groups.entries()).map(([dateLabel, photos]) => ({
            dateLabel,
            photos,
        }));
    }, [visiblePhotos]);

    const visiblePhotoOrder = useMemo(
        () => new Map(visiblePhotos.map((p, index) => [p.fileId, index])),
        [visiblePhotos],
    );

    return {
        visiblePhotos,
        setVisiblePhotos,
        visiblePhotosWave,
        photoGroups,
        visiblePhotoOrder,
    };
}

/**
 * Creates custom icons for map marker clusters with thumbnails
 * Responsibility: Generate cluster icons showing photo thumbnail and count
 */
function useClusterIcon(
    mapPhotos: JourneyPoint[],
    thumbByFileID: Map<number, string>,
) {
    const photosByPosition = useMemo(() => {
        const map = new Map<string, JourneyPoint>();
        mapPhotos.forEach((photo) => {
            map.set(`${photo.lat},${photo.lng}`, photo);
        });
        return map;
    }, [mapPhotos]);

    return useCallback(
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        (cluster: any) => {
            // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-call
            const count = cluster.getChildCount();
            // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-call
            const childMarkers = cluster.getAllChildMarkers();

            let thumbnailUrl = "";
            for (const marker of childMarkers) {
                // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-call
                const latlng = marker.getLatLng();
                // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
                const key = `${latlng.lat},${latlng.lng}`;
                const photo = photosByPosition.get(key);
                if (photo) {
                    const thumb = getPhotoThumbnail(photo, thumbByFileID);
                    if (thumb) {
                        thumbnailUrl = thumb;
                        break;
                    }
                }
            }

            // eslint-disable-next-line @typescript-eslint/no-unsafe-argument
            return createIcon(thumbnailUrl, 68, "#f6f6f6", count, false);
        },
        [photosByPosition, thumbByFileID],
    );
}

// ============================================================================
// Helper Functions
// ============================================================================

/**
 * Extracts thumbnail URL from either the thumbByFileID map or the photo's embedded image
 */
function getPhotoThumbnail(
    photo: JourneyPoint,
    thumbByFileID: Map<number, string>,
): string | undefined {
    return thumbByFileID.get(photo.fileId) ?? photo.image;
}

/**
 * Sorts journey points by timestamp in descending order (newest first)
 */
function sortPhotosByTimestamp(photos: JourneyPoint[]): JourneyPoint[] {
    return [...photos].sort(
        (a, b) =>
            new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime(),
    );
}

/**
 * Formats a timestamp string into a human-readable date label
 */
function formatDateLabel(timestamp: string): string {
    return new Date(timestamp).toLocaleDateString(undefined, {
        weekday: "long",
        day: "numeric",
        month: "short",
    });
}

/**
 * Loads every file stored in IndexedDB, filters those belonging to the
 * target collection, removes duplicates by ID, and returns the unique set.
 */
async function getFilesForCollection(
    activeCollection: Collection,
): Promise<EnteFile[]> {
    const allFiles = await savedCollectionFiles();
    const filtered = allFiles.filter(
        (file) => file.collectionID === activeCollection.id,
    );
    return uniqueFilesByID(filtered);
}

function extractLocationPoints(files: EnteFile[]): JourneyPoint[] {
    const points: JourneyPoint[] = [];

    for (const file of files) {
        const loc = fileLocation(file);
        if (!loc) continue;

        points.push({
            lat: loc.latitude,
            lng: loc.longitude,
            name: fileFileName(file),
            country: "",
            timestamp: new Date(fileCreationTime(file) / 1000).toISOString(),
            image: "",
            fileId: file.id,
        });
    }

    return points;
}

// ============================================================================
// Main Component
// ============================================================================

/**
 * Main dialog component that displays a collection's photos on an interactive map
 * Responsibility: Coordinate all hooks, manage dialog state, render map layout or loading states
 */
export const CollectionMapDialog: React.FC<CollectionMapDialogProps> = ({
    open,
    onClose,
    collectionSummary,
    activeCollection,
}) => {
    const { onGenericError } = useBaseContext();
    const mapComponents = useMapComponents();
    const user = useCurrentUser();
    const optimalZoom = calculateOptimalZoom();

    const { mapCenter, mapPhotos, filesByID, thumbByFileID, isLoading, error } =
        useMapData(open, activeCollection, onGenericError);

    const {
        visiblePhotos,
        setVisiblePhotos,
        visiblePhotosWave,
        photoGroups,
        visiblePhotoOrder,
    } = useVisiblePhotos();

    const {
        favoriteFileIDs,
        pendingFavoriteUpdates,
        pendingVisibilityUpdates,
        handleToggleFavorite,
        handleFileVisibilityUpdate,
    } = useFavorites(open, user);

    const {
        open: openFileViewer,
        currentIndex: currentFileIndex,
        files: viewerFiles,
        handlePhotoClick,
        handleClose: handleCloseFileViewer,
    } = useFileViewer(filesByID, visiblePhotos);

    const createClusterCustomIcon = useClusterIcon(mapPhotos, thumbByFileID);

    const body = useMemo(() => {
        if (isLoading) {
            return (
                <CenteredBox>
                    <ActivityIndicator size="28px" />
                </CenteredBox>
            );
        }

        if (error) {
            return (
                <CenteredBox>
                    <Typography variant="body" color="text.secondary">
                        {error}
                    </Typography>
                </CenteredBox>
            );
        }

        if (!mapComponents) {
            return (
                <CenteredBox>
                    <Typography variant="body" color="text.secondary">
                        {t("loading")}
                    </Typography>
                </CenteredBox>
            );
        }

        if (!mapPhotos.length || !mapCenter) {
            return (
                <CenteredBox onClose={onClose} closeLabel={t("close")}>
                    <Typography variant="body" color="text.secondary">
                        {t("view_on_map")}
                    </Typography>
                    <Typography variant="small" color="text.secondary">
                        {t("maps_privacy_notice")}
                    </Typography>
                </CenteredBox>
            );
        }

        return (
            <MapLayout
                collectionSummary={collectionSummary}
                visiblePhotos={visiblePhotos}
                photoGroups={photoGroups}
                mapPhotos={mapPhotos}
                thumbByFileID={thumbByFileID}
                visiblePhotoOrder={visiblePhotoOrder}
                visiblePhotosWave={visiblePhotosWave}
                mapComponents={mapComponents}
                mapCenter={mapCenter}
                optimalZoom={optimalZoom}
                createClusterCustomIcon={createClusterCustomIcon}
                onClose={onClose}
                onVisiblePhotosChange={setVisiblePhotos}
                onPhotoClick={handlePhotoClick}
            />
        );
    }, [
        collectionSummary,
        createClusterCustomIcon,
        error,
        handlePhotoClick,
        isLoading,
        mapCenter,
        mapComponents,
        mapPhotos,
        onClose,
        optimalZoom,
        photoGroups,
        setVisiblePhotos,
        thumbByFileID,
        visiblePhotoOrder,
        visiblePhotos,
        visiblePhotosWave,
    ]);

    return (
        <>
            <FileViewer
                open={openFileViewer}
                onClose={handleCloseFileViewer}
                initialIndex={currentFileIndex}
                files={viewerFiles}
                user={user}
                favoriteFileIDs={favoriteFileIDs}
                pendingFavoriteUpdates={pendingFavoriteUpdates}
                pendingVisibilityUpdates={pendingVisibilityUpdates}
                onToggleFavorite={handleToggleFavorite}
                onFileVisibilityUpdate={handleFileVisibilityUpdate}
                onVisualFeedback={() => {
                    /* no-op for map view */
                }}
                zIndex={1301}
            />

            <Dialog fullScreen open={open} onClose={onClose}>
                <Box
                    sx={{
                        position: "relative",
                        width: "100vw",
                        height: "100vh",
                        bgcolor: "background.default",
                    }}
                >
                    <DialogContent
                        sx={{ padding: "0 !important", height: "100%" }}
                    >
                        {body}
                    </DialogContent>
                </Box>
            </Dialog>
        </>
    );
};

// ============================================================================
// Layout Components
// ============================================================================

/**
 * Main layout container for map and sidebar
 * Responsibility: Position sidebar and map canvas side-by-side
 */
interface MapLayoutProps {
    collectionSummary: CollectionSummary;
    visiblePhotos: JourneyPoint[];
    photoGroups: PhotoGroup[];
    mapPhotos: JourneyPoint[];
    thumbByFileID: Map<number, string>;
    visiblePhotoOrder: Map<number, number>;
    visiblePhotosWave: number;
    mapComponents: MapComponents;
    mapCenter: [number, number];
    optimalZoom: number;
    createClusterCustomIcon: (cluster: unknown) => unknown;
    onClose: () => void;
    onVisiblePhotosChange: (photosInView: JourneyPoint[]) => void;
    onPhotoClick: (fileId: number) => void;
}

function MapLayout({
    collectionSummary,
    visiblePhotos,
    photoGroups,
    mapPhotos,
    thumbByFileID,
    visiblePhotoOrder,
    visiblePhotosWave,
    mapComponents,
    mapCenter,
    optimalZoom,
    createClusterCustomIcon,
    onClose,
    onVisiblePhotosChange,
    onPhotoClick,
}: MapLayoutProps) {
    return (
        <Box sx={{ position: "relative", height: "100%", width: "100%" }}>
            <CollectionSidebar
                collectionSummary={collectionSummary}
                visibleCount={visiblePhotos.length}
                photoGroups={photoGroups}
                mapPhotos={mapPhotos}
                thumbByFileID={thumbByFileID}
                visiblePhotoOrder={visiblePhotoOrder}
                visiblePhotosWave={visiblePhotosWave}
                onPhotoClick={onPhotoClick}
                onClose={onClose}
            />
            <Box sx={{ width: "100%", height: "100%" }}>
                <MapCanvas
                    mapComponents={mapComponents}
                    mapCenter={mapCenter}
                    mapPhotos={mapPhotos}
                    optimalZoom={optimalZoom}
                    thumbByFileID={thumbByFileID}
                    createClusterCustomIcon={createClusterCustomIcon}
                    onVisiblePhotosChange={onVisiblePhotosChange}
                />
            </Box>
        </Box>
    );
}

// ============================================================================
// Sidebar Components
// ============================================================================

/**
 * Sidebar displaying collection details and photo thumbnails
 * Responsibility: Show collection cover, sticky header with date, scrollable photo grid
 */
interface CollectionSidebarProps {
    collectionSummary: CollectionSummary;
    visibleCount: number;
    photoGroups: PhotoGroup[];
    mapPhotos: JourneyPoint[];
    thumbByFileID: Map<number, string>;
    visiblePhotoOrder: Map<number, number>;
    visiblePhotosWave: number;
    onPhotoClick: (fileId: number) => void;
    onClose: () => void;
}

function CollectionSidebar({
    collectionSummary,
    visibleCount,
    photoGroups,
    mapPhotos,
    thumbByFileID,
    visiblePhotoOrder,
    visiblePhotosWave,
    onPhotoClick,
    onClose,
}: CollectionSidebarProps) {
    const [isCoverHidden, setIsCoverHidden] = useState(false);
    const [currentDateLabel, setCurrentDateLabel] = useState<string | null>(
        null,
    );
    const coverRef = useRef<HTMLDivElement>(null);
    const sidebarRef = useRef<HTMLDivElement>(null);

    // Animated counter for memories
    const animatedCount = useAnimatedCounter(visibleCount, 400);

    // Reset current date when scrolled back to top
    const handleScroll = useCallback(() => {
        const sidebar = sidebarRef.current;
        if (!sidebar) return;

        // If scrolled near the top, clear the current date label
        if (sidebar.scrollTop < 50) {
            setCurrentDateLabel(null);
        }
    }, []);

    // Handle date visibility callback from PhotoDateGroup
    const handleDateVisible = useCallback((dateLabel: string) => {
        setCurrentDateLabel(dateLabel);
    }, []);

    // Get the first photo's thumbnail as the cover image
    // Note: mapPhotos are already sorted by timestamp (newest first)
    const coverImageUrl = useMemo(() => {
        if (!mapPhotos.length) return undefined;
        const firstPhoto = mapPhotos[0];
        if (!firstPhoto) return undefined;
        return getPhotoThumbnail(firstPhoto, thumbByFileID);
    }, [mapPhotos, thumbByFileID]);

    // Detect when cover scrolls out of view
    useEffect(() => {
        const cover = coverRef.current;
        if (!cover) return;

        const observer = new IntersectionObserver(
            ([entry]) => {
                setIsCoverHidden(entry ? !entry.isIntersecting : false);
            },
            { threshold: 0 },
        );

        observer.observe(cover);
        return () => observer.disconnect();
    }, []);

    return (
        <Box
            ref={sidebarRef}
            onScroll={handleScroll}
            sx={{
                position: "absolute",
                // Desktop: left sidebar taking 35% width
                left: { xs: 0, md: 16 },
                top: { xs: "auto", md: 16 },
                bottom: { xs: 0, md: 16 },
                right: { xs: 0, md: "auto" },
                width: { xs: "100%", md: "35%" },
                height: { xs: "50%", md: "auto" },
                maxWidth: { md: "600px" },
                minWidth: { md: "450px" },
                bgcolor: (theme) => theme.vars.palette.background.paper,
                boxShadow: (theme) => theme.shadows[10],
                display: "flex",
                flexDirection: "column",
                overflowY: "auto",
                overflowX: "hidden",
                // Desktop: rounded corners on all sides; Mobile: only top corners
                borderRadius: { xs: "24px 24px 0 0", md: "48px" },
                zIndex: 1000,
                "&::-webkit-scrollbar": { width: "8px" },
                "&::-webkit-scrollbar-track": {
                    background: "transparent",
                    borderRadius: "48px",
                },
                "&::-webkit-scrollbar-thumb": {
                    background: (theme) => theme.palette.divider,
                    borderRadius: "48px",
                    "&:hover": {
                        background: (theme) => theme.palette.text.disabled,
                    },
                },
                scrollbarWidth: "thin",
                scrollbarColor: (theme) =>
                    `${theme.palette.divider} transparent`,
                // Bottom gradient overlay
                "&::after": {
                    content: '""',
                    position: "sticky",
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: "150px",
                    background:
                        "linear-gradient(to top, rgba(0,0,0,1) 0%, rgba(0,0,0,0.65) 40%, rgba(0,0,0,0) 100%)",
                    pointerEvents: "none",
                    flexShrink: 0,
                    marginTop: "-100px",
                    borderRadius: { xs: "0", md: "0 0 48px 48px" },
                },
            }}
        >
            <Box ref={coverRef}>
                <MapCover
                    name={collectionSummary.name}
                    coverImageUrl={coverImageUrl}
                    visibleCount={visibleCount}
                    onClose={onClose}
                />
            </Box>

            {/* Sticky header */}
            <Box
                sx={{
                    position: "sticky",
                    top: 0,
                    zIndex: 10,
                    bgcolor: (theme) => theme.vars.palette.background.paper,
                    px: { xs: "24px", md: "32px" },
                    pt: { xs: 2, md: 4 },
                    pb: 2,
                    display: isCoverHidden ? "flex" : "none",
                    justifyContent: "space-between",
                    alignItems: "center",
                    borderBottom: (theme) =>
                        `1px solid ${theme.palette.divider}`,
                }}
            >
                <Stack spacing={0.25} sx={{ minWidth: 0, flex: 1 }}>
                    <Typography
                        variant="body"
                        sx={{ fontWeight: 600, lineHeight: 1.2 }}
                        noWrap
                    >
                        {collectionSummary.name}
                    </Typography>
                    <Typography variant="small" color="text.secondary">
                        {(currentDateLabel ?? photoGroups[0]?.dateLabel)
                            ? `${currentDateLabel ?? photoGroups[0]?.dateLabel} • ${animatedCount} memories`
                            : `${animatedCount} memories`}
                    </Typography>
                </Stack>
                <IconButton
                    aria-label="Close"
                    onClick={onClose}
                    size="small"
                    sx={{
                        ml: 1,
                        bgcolor: (theme) => theme.vars.palette.fill.faint,
                    }}
                >
                    <CloseIcon fontSize="small" />
                </IconButton>
            </Box>

            <Box
                sx={{
                    px: { xs: "24px", md: "32px" },
                    pb: { xs: "24px", md: "32px" },
                    position: "relative",
                }}
            >
                <PhotoList
                    photoGroups={photoGroups}
                    thumbByFileID={thumbByFileID}
                    visiblePhotoOrder={visiblePhotoOrder}
                    visiblePhotosWave={visiblePhotosWave}
                    onPhotoClick={onPhotoClick}
                    onDateVisible={handleDateVisible}
                    scrollContainerRef={sidebarRef}
                />
            </Box>
        </Box>
    );
}

/**
 * Renders the list of photo groups or empty state
 * Responsibility: Display grouped photos or show "no photos" message
 */
interface PhotoListProps {
    photoGroups: PhotoGroup[];
    thumbByFileID: Map<number, string>;
    visiblePhotoOrder: Map<number, number>;
    visiblePhotosWave: number;
    onPhotoClick: (fileId: number) => void;
    onDateVisible?: (dateLabel: string) => void;
    scrollContainerRef?: React.RefObject<HTMLDivElement | null>;
}

function PhotoList({
    photoGroups,
    thumbByFileID,
    visiblePhotoOrder,
    visiblePhotosWave,
    onPhotoClick,
    onDateVisible,
    scrollContainerRef,
}: PhotoListProps) {
    if (!photoGroups.length) {
        return (
            <EmptyState>
                <Typography variant="body" sx={{ fontWeight: 600 }}>
                    {t("no_photos_found_here", {
                        defaultValue: "No photos found here",
                    })}
                </Typography>
                <Typography variant="small" color="text.secondary">
                    {t("zoom_out_to_see_photos", {
                        defaultValue: "Zoom out to see photos",
                    })}
                </Typography>
            </EmptyState>
        );
    }

    return (
        <Stack spacing={1.5}>
            {photoGroups.map(({ dateLabel, photos }) => (
                <PhotoDateGroup
                    key={dateLabel}
                    dateLabel={dateLabel}
                    photos={photos}
                    thumbByFileID={thumbByFileID}
                    visiblePhotoOrder={visiblePhotoOrder}
                    visiblePhotosWave={visiblePhotosWave}
                    onPhotoClick={onPhotoClick}
                    onDateVisible={onDateVisible}
                    scrollContainerRef={scrollContainerRef}
                />
            ))}
        </Stack>
    );
}

/**
 * Renders a date-grouped section of photos with intersection observer for sticky header
 * Responsibility: Display date header and thumbnail grid, notify parent when scrolled into view
 */
interface PhotoDateGroupProps {
    dateLabel: string;
    photos: JourneyPoint[];
    thumbByFileID: Map<number, string>;
    visiblePhotoOrder: Map<number, number>;
    visiblePhotosWave: number;
    onPhotoClick: (fileId: number) => void;
    onDateVisible?: (dateLabel: string) => void;
    scrollContainerRef?: React.RefObject<HTMLDivElement | null>;
}

const PhotoDateGroup = React.memo(function PhotoDateGroup({
    dateLabel,
    photos,
    thumbByFileID,
    visiblePhotoOrder,
    visiblePhotosWave,
    onPhotoClick,
    onDateVisible,
    scrollContainerRef,
}: PhotoDateGroupProps) {
    const headerRef = useRef<HTMLDivElement>(null);

    // Track when this date group's header scrolls out of view at the top
    useEffect(() => {
        const header = headerRef.current;
        const scrollContainer = scrollContainerRef?.current;
        if (!header || !onDateVisible) return;

        const observer = new IntersectionObserver(
            ([entry]) => {
                // When header is not intersecting (scrolled past top), this date is "current"
                if (entry && !entry.isIntersecting) {
                    const rect = entry.boundingClientRect;
                    const rootRect = scrollContainer?.getBoundingClientRect();
                    const topThreshold = rootRect?.top ?? 0;
                    if (rect.top < topThreshold + 100) {
                        onDateVisible(dateLabel);
                    }
                }
            },
            {
                threshold: 0,
                root: scrollContainer ?? null,
                rootMargin: "-100px 0px 0px 0px",
            },
        );

        observer.observe(header);
        return () => observer.disconnect();
    }, [dateLabel, onDateVisible, scrollContainerRef]);

    return (
        <Stack spacing={0.75}>
            <Box ref={headerRef} sx={{ pt: 1.5, pb: 1.5 }}>
                <Typography variant="small" color="text.secondary">
                    {dateLabel}
                </Typography>
            </Box>
            <ThumbGrid>
                {photos.map((photo, idx) => {
                    const thumb = thumbByFileID.get(photo.fileId);
                    const delay =
                        (visiblePhotoOrder.get(photo.fileId) ?? idx) * 15;
                    return (
                        <ThumbImage
                            key={`${photo.fileId}-${visiblePhotosWave}`}
                            src={thumb}
                            onClick={() => onPhotoClick(photo.fileId)}
                            animationDelay={delay}
                        />
                    );
                })}
            </ThumbGrid>
        </Stack>
    );
});

// ============================================================================
// Map Components
// ============================================================================

/**
 * Renders the Leaflet map with markers, clusters, and controls
 * Responsibility: Display interactive map with photo markers and handle viewport changes
 */
interface MapCanvasProps {
    mapComponents: MapComponents;
    mapCenter: [number, number];
    mapPhotos: JourneyPoint[];
    optimalZoom: number;
    thumbByFileID: Map<number, string>;
    createClusterCustomIcon: (cluster: unknown) => unknown;
    onVisiblePhotosChange: (photosInView: JourneyPoint[]) => void;
}

const MapCanvas = React.memo(function MapCanvas({
    mapComponents,
    mapCenter,
    mapPhotos,
    optimalZoom,
    thumbByFileID,
    createClusterCustomIcon,
    onVisiblePhotosChange,
}: MapCanvasProps) {
    const { MapContainer, TileLayer, Marker, useMap, MarkerClusterGroup } =
        mapComponents;

    // Memoize marker icons to prevent recreation on every render
    // Key: fileId, Value: Leaflet icon instance
    const markerIcons = useMemo(() => {
        const icons = new Map<number, ReturnType<typeof createIcon>>();
        for (const photo of mapPhotos) {
            const thumbnail = getPhotoThumbnail(photo, thumbByFileID);
            icons.set(
                photo.fileId,
                createIcon(thumbnail ?? "", 68, "#f6f6f6", undefined, false),
            );
        }
        return icons;
    }, [mapPhotos, thumbByFileID]);

    return (
        <MapContainer
            center={mapCenter}
            zoom={optimalZoom}
            scrollWheelZoom
            zoomControl={false}
            style={{ width: "100%", height: "100%" }}
        >
            <TileLayer
                attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
                url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                maxZoom={19}
                updateWhenZooming
            />
            <MapControls useMap={useMap} />
            <MapViewportListener
                useMap={useMap}
                photos={mapPhotos}
                onVisiblePhotosChange={onVisiblePhotosChange}
            />
            <MarkerClusterGroup
                chunkedLoading
                iconCreateFunction={createClusterCustomIcon}
                maxClusterRadius={80}
                spiderfyOnMaxZoom
                showCoverageOnHover={false}
                zoomToBoundsOnClick
                animate
                animateAddingMarkers
                spiderfyDistanceMultiplier={1.5}
            >
                {mapPhotos.map((photo) => (
                    <Marker
                        key={photo.fileId}
                        position={[photo.lat, photo.lng]}
                        icon={markerIcons.get(photo.fileId) ?? undefined}
                    />
                ))}
            </MarkerClusterGroup>
        </MapContainer>
    );
});

/**
 * Floating map control buttons (open in Maps, zoom in/out)
 * Responsibility: Provide map navigation and external link controls
 */
interface MapControlsProps {
    useMap: typeof import("react-leaflet").useMap;
}

const MapControls = React.memo(function MapControls({
    useMap,
}: MapControlsProps) {
    const map = useMap();

    const handleOpenInMaps = useCallback(() => {
        const center = map.getCenter();
        const url = `https://www.google.com/maps?q=${center.lat},${center.lng}&z=${map.getZoom()}`;
        window.open(url, "_blank", "noopener,noreferrer");
    }, [map]);

    const handleZoomIn = useCallback(() => map.zoomIn(), [map]);
    const handleZoomOut = useCallback(() => map.zoomOut(), [map]);

    return (
        <>
            <FloatingIconButton
                onClick={handleOpenInMaps}
                sx={{ position: "absolute", right: 16, top: 16, zIndex: 1000 }}
            >
                <NavigationIcon />
            </FloatingIconButton>

            <Stack
                spacing={1}
                sx={{
                    position: "absolute",
                    right: 16,
                    bottom: 16,
                    zIndex: 1000,
                }}
            >
                <FloatingIconButton onClick={handleZoomIn}>
                    <AddIcon />
                </FloatingIconButton>
                <FloatingIconButton onClick={handleZoomOut}>
                    <RemoveIcon />
                </FloatingIconButton>
            </Stack>
        </>
    );
});

/**
 * Listens to map viewport changes and updates visible photos
 * Responsibility: Track map bounds and notify parent of visible photos when viewport changes
 */
interface MapViewportListenerProps {
    useMap: typeof import("react-leaflet").useMap;
    photos: JourneyPoint[];
    onVisiblePhotosChange: (photosInView: JourneyPoint[]) => void;
}

function MapViewportListener({
    useMap,
    photos,
    onVisiblePhotosChange,
}: MapViewportListenerProps) {
    const map = useMap();
    const previousVisibleIdsRef = useRef<Set<number>>(new Set());
    const previousClusterCountRef = useRef<number>(0);

    // Cache cluster count query result to avoid repeated DOM queries
    const getClusterCount = useCallback(
        () => map.getContainer().querySelectorAll(".marker-cluster").length,
        [map],
    );

    const updateVisiblePhotos = useCallback(() => {
        const bounds = map.getBounds();
        const inView = photos.filter((p) => bounds.contains([p.lat, p.lng]));

        // Use Set comparison instead of string join for O(n) vs O(n log n + n)
        const currentIds = new Set(inView.map((p) => p.fileId));
        const previousIds = previousVisibleIdsRef.current;

        const clusterCount = getClusterCount();
        const clusterChanged = previousClusterCountRef.current !== clusterCount;

        // Check if sets are equal (same size and all elements match)
        const setsEqual =
            currentIds.size === previousIds.size &&
            [...currentIds].every((id) => previousIds.has(id));

        if (setsEqual && !clusterChanged) {
            return;
        }

        previousVisibleIdsRef.current = currentIds;
        previousClusterCountRef.current = clusterCount;
        onVisiblePhotosChange(inView);
    }, [getClusterCount, map, onVisiblePhotosChange, photos]);

    useEffect(() => {
        if (!photos.length) {
            previousVisibleIdsRef.current = new Set();
            previousClusterCountRef.current = getClusterCount();
            onVisiblePhotosChange([]);
            return;
        }
        updateVisiblePhotos();
    }, [getClusterCount, photos, onVisiblePhotosChange, updateVisiblePhotos]);

    useEffect(() => {
        map.on("moveend", updateVisiblePhotos);
        map.on("zoomend", updateVisiblePhotos);
        return () => {
            map.off("moveend", updateVisiblePhotos);
            map.off("zoomend", updateVisiblePhotos);
        };
    }, [map, updateVisiblePhotos]);

    return null;
}

// ============================================================================
// UI Components
// ============================================================================

/**
 * Styled floating action button with consistent styling
 * Responsibility: Provide consistent button styling for map controls
 */
const FloatingIconButton: React.FC<IconButtonProps> = ({ sx, ...props }) => {
    const baseSx = {
        bgcolor: (theme: {
            vars: { palette: { background: { paper: string } } };
        }) => theme.vars.palette.background.paper,
        boxShadow: (theme: { shadows: string[] }) => theme.shadows[4],
        width: 48,
        height: 48,
        borderRadius: "16px",
        transition: "transform 0.2s ease-out",
        "&:hover": {
            bgcolor: (theme: {
                vars: { palette: { background: { paper: string } } };
            }) => theme.vars.palette.background.paper,
            transform: "scale(1.05)",
        },
    };

    const mergedSx =
        sx == null
            ? baseSx
            : Array.isArray(sx)
              ? // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
                [baseSx, ...sx]
              : [baseSx, sx];

    return <IconButton {...props} sx={mergedSx} />;
};

/**
 * Centered container for loading/error states with optional close button
 * Responsibility: Display centered content like loading spinners or error messages
 */
interface CenteredBoxProps extends React.PropsWithChildren {
    onClose?: () => void;
    closeLabel?: string;
}

function CenteredBox({ children, onClose, closeLabel }: CenteredBoxProps) {
    return (
        <Box
            sx={{
                width: "100%",
                height: "100%",
                minHeight: "420px",
                position: "relative",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                gap: 1,
                flexDirection: "column",
                textAlign: "center",
            }}
        >
            {onClose && (
                <IconButton
                    aria-label={closeLabel ?? "Close"}
                    onClick={onClose}
                    sx={{ position: "absolute", top: 16, right: 16 }}
                >
                    <CloseIcon />
                </IconButton>
            )}
            {children}
        </Box>
    );
}

/**
 * Empty state placeholder for when no photos are visible
 * Responsibility: Display empty state message when no photos match filters
 */
function EmptyState({ children }: React.PropsWithChildren) {
    return (
        <Box
            sx={{
                minHeight: "100%",
                display: "flex",
                flexDirection: "column",
                alignItems: "center",
                justifyContent: "center",
                textAlign: "center",
                py: 4,
                color: (theme) => theme.vars.palette.text.secondary,
                gap: 0.5,
            }}
        >
            {children}
        </Box>
    );
}

// ============================================================================
// Map Cover Component
// ============================================================================

/**
 * Hero image cover for the collection with title and memory count
 * Responsibility: Display collection cover image, name, and visible memory count
 */
interface MapCoverProps {
    name: string;
    coverImageUrl: string | undefined;
    visibleCount: number;
    onClose: () => void;
}

const MapCover = React.memo(function MapCover({
    name,
    coverImageUrl,
    visibleCount,
    onClose,
}: MapCoverProps) {
    return (
        <CoverContainer>
            <CoverImageContainer>
                {coverImageUrl ? (
                    <>
                        <img
                            src={coverImageUrl}
                            alt="Cover"
                            style={{
                                position: "absolute",
                                inset: 0,
                                width: "100%",
                                height: "100%",
                                objectFit: "cover",
                            }}
                        />
                        <CoverGradientOverlay />
                    </>
                ) : (
                    <Skeleton
                        variant="rectangular"
                        width="100%"
                        height="100%"
                        sx={{ bgcolor: "rgba(128, 128, 128, 0.2)" }}
                    />
                )}

                <CoverCloseButton aria-label="Close" onClick={onClose}>
                    <CloseIcon sx={{ fontSize: 20 }} />
                </CoverCloseButton>

                <CoverContentContainer>
                    {coverImageUrl ? (
                        <>
                            <CoverTitle>{name}</CoverTitle>
                            <CoverSubtitle>
                                {visibleCount} memories
                            </CoverSubtitle>
                        </>
                    ) : (
                        <>
                            <Skeleton
                                variant="text"
                                width="180px"
                                height="32px"
                                sx={{ bgcolor: "rgba(255,255,255,0.3)" }}
                            />
                            <Skeleton
                                variant="text"
                                width="220px"
                                height="20px"
                                sx={{ bgcolor: "rgba(255,255,255,0.2)" }}
                            />
                        </>
                    )}
                </CoverContentContainer>
            </CoverImageContainer>
        </CoverContainer>
    );
});

const CoverContainer = styled(Box)(({ theme }) => ({
    width: "100%",
    flexShrink: 0,
    padding: "16px",
    paddingBottom: "8px",
    [theme.breakpoints.down("md")]: { padding: "8px", paddingBottom: "4px" },
}));

const CoverImageContainer = styled(Box)({
    aspectRatio: "16/9",
    position: "relative",
    overflow: "hidden",
    backgroundColor: "#333",
    borderRadius: "36px 36px 24px 24px",
    marginTop: "2px",
});

const CoverGradientOverlay = styled(Box)({
    position: "absolute",
    inset: 0,
    background:
        "linear-gradient(to bottom, rgba(0,0,0,0.4), transparent 35%, transparent 60%, rgba(0,0,0,0.75))",
});

const CoverCloseButton = styled(IconButton)({
    position: "absolute",
    top: "12px",
    right: "12px",
    color: "white",
    backgroundColor: "rgba(0, 0, 0, 0.3)",
    "&:hover": { backgroundColor: "rgba(0, 0, 0, 0.5)" },
});

const CoverContentContainer = styled(Box)({
    position: "absolute",
    bottom: 0,
    left: 0,
    right: 0,
    padding: "24px",
    paddingLeft: "18px",
    color: "white",
});

const CoverTitle = styled(Typography)({
    fontSize: "22px",
    fontWeight: "bold",
    marginBottom: "6px",
    lineHeight: 1.2,
});

const CoverSubtitle = styled(Typography)({
    color: "rgba(255, 255, 255, 0.85)",
    fontSize: "14px",
    fontWeight: "500",
});

// ============================================================================
// Thumbnail Components
// ============================================================================

/**
 * Animation for thumbnails appearing in sequence
 */
const cascadeFadeIn = keyframes`
    from {
        opacity: 0;
        transform: translate3d(0, 8px, 0) scale(0.99);
    }
    to {
        opacity: 1;
        transform: translate3d(0, 0, 0) scale(1);
    }
`;

/**
 * Grid container for thumbnail images
 * Responsibility: Layout thumbnails in a responsive grid
 */
function ThumbGrid({ children }: React.PropsWithChildren) {
    return (
        <Box
            sx={{
                display: "grid",
                gridTemplateColumns: "repeat(auto-fill, minmax(120px, 1fr))",
                gap: 0.25,
                pb: 1,
                overflow: "hidden",
            }}
        >
            {children}
        </Box>
    );
}

/**
 * Individual thumbnail image with animation and hover effects
 * Responsibility: Display a single thumbnail with staggered fade-in animation
 */
interface ThumbImageProps {
    src: string | undefined;
    onClick: () => void;
    animationDelay: number;
}

// Static styles moved outside component to prevent recreation on every render
const thumbPlaceholderBaseSx = {
    width: "100%",
    aspectRatio: "1",
    borderRadius: 0,
    border: (theme: { palette: { divider: string } }) =>
        `1px solid ${theme.palette.divider}`,
    opacity: 0,
    transformOrigin: "top left",
} as const;

const thumbImageContainerBaseSx = {
    position: "relative",
    width: "100%",
    aspectRatio: "1",
    cursor: "pointer",
    overflow: "hidden",
    opacity: 0,
    "&::after": {
        content: '""',
        position: "absolute",
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        background:
            "linear-gradient(135deg, rgba(255,255,255,0.15) 0%, rgba(255,255,255,0) 50%)",
        opacity: 0,
        transition: "opacity 0.3s ease-out",
        pointerEvents: "none",
    },
    "&:hover::after": { opacity: 1 },
} as const;

const thumbImgSx = {
    width: "100%",
    height: "100%",
    objectFit: "cover",
    border: (theme: { palette: { divider: string } }) =>
        `1px solid ${theme.palette.divider}`,
} as const;

const ThumbImage = React.memo(function ThumbImage({
    src,
    onClick,
    animationDelay,
}: ThumbImageProps) {
    // Only animation-related styles need to be dynamic
    const animationSx = useMemo(
        () => ({
            animation: `${cascadeFadeIn} 200ms ease-out forwards`,
            animationDelay: `${animationDelay}ms`,
        }),
        [animationDelay],
    );

    if (!src) {
        return (
            <Box
                sx={{
                    ...thumbPlaceholderBaseSx,
                    ...animationSx,
                    bgcolor: (theme) => theme.vars.palette.fill.faint,
                }}
            />
        );
    }

    return (
        <Box
            onClick={onClick}
            sx={{
                ...thumbImageContainerBaseSx,
                ...animationSx,
            }}
        >
            <Box component="img" src={src} alt="" sx={thumbImgSx} />
        </Box>
    );
});
