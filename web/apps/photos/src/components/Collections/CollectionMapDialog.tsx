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

function useCurrentUser() {
    return useMemo(() => {
        try {
            return ensureLocalUser();
        } catch {
            return undefined;
        }
    }, []);
}

function useMapData(
    open: boolean,
    collectionSummary: CollectionSummary,
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
            const entries = await Promise.all(
                points.map(async (p) => {
                    if (p.image) return [p.fileId, p.image] as const;
                    const file = files.find((f) => f.id === p.fileId);
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
                    locationPoints.sort(
                        (a, b) =>
                            new Date(b.timestamp).getTime() -
                            new Date(a.timestamp).getTime(),
                    );

                    const { thumbnailUpdates } = await generateNeededThumbnails(
                        { photoClusters: [locationPoints], files },
                    );

                    const pointsWithThumbs = locationPoints.map((point) => {
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
    }, [
        open,
        collectionSummary,
        activeCollection,
        onGenericError,
        loadAllThumbs,
    ]);

    return state;
}

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

    const handleToggleFavorite = useCallback(
        async (file: EnteFile) => {
            if (!user) return;
            const fileID = file.id;
            const isFavorite = favoriteFileIDs.has(fileID);

            setPendingFavoriteUpdates((prev) => new Set(prev).add(fileID));
            try {
                const action = isFavorite
                    ? removeFromFavoritesCollection
                    : addToFavoritesCollection;
                await action([file]);
                setFavoriteFileIDs((prev) => {
                    const next = new Set(prev);
                    if (isFavorite) {
                        next.delete(fileID);
                    } else {
                        next.add(fileID);
                    }
                    return next;
                });
            } finally {
                setPendingFavoriteUpdates((prev) => {
                    const next = new Set(prev);
                    next.delete(fileID);
                    return next;
                });
            }
        },
        [user, favoriteFileIDs],
    );

    const handleFileVisibilityUpdate = useCallback(
        async (file: EnteFile, visibility: ItemVisibility) => {
            const fileID = file.id;
            setPendingVisibilityUpdates((prev) => new Set(prev).add(fileID));
            try {
                await updateFilesVisibility([file], visibility);
            } finally {
                setPendingVisibilityUpdates((prev) => {
                    const next = new Set(prev);
                    next.delete(fileID);
                    return next;
                });
            }
        },
        [],
    );

    return {
        favoriteFileIDs,
        pendingFavoriteUpdates,
        pendingVisibilityUpdates,
        handleToggleFavorite,
        handleFileVisibilityUpdate,
    };
}

// Encapsulates FileViewer open state, visible file ordering, and click handlers
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
            const visibleFileIds = new Set(visiblePhotos.map((p) => p.fileId));
            const visibleFiles = Array.from(filesByID.values())
                .filter((f) => visibleFileIds.has(f.id))
                .sort(
                    (a, b) =>
                        new Date(fileCreationTime(b) / 1000).getTime() -
                        new Date(fileCreationTime(a) / 1000).getTime(),
                );

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
                    const thumb =
                        thumbByFileID.get(photo.fileId) ?? photo.image;
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
        useMapData(open, collectionSummary, activeCollection, onGenericError);

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
    const coverRef = useRef<HTMLDivElement>(null);

    // Get the first photo's thumbnail as the cover image
    const coverImageUrl = useMemo(() => {
        if (!mapPhotos.length) return undefined;
        // Sort by timestamp to get the most recent photo for the cover
        const sorted = [...mapPhotos].sort(
            (a, b) =>
                new Date(b.timestamp).getTime() -
                new Date(a.timestamp).getTime(),
        );
        const firstPhoto = sorted[0];
        if (!firstPhoto) return undefined;
        return thumbByFileID.get(firstPhoto.fileId) ?? firstPhoto.image;
    }, [mapPhotos, thumbByFileID]);

    // Calculate cover stats for the sticky header
    const coverStats = useMemo(() => {
        if (!mapPhotos.length) return null;

        const sortedData = [...mapPhotos].sort(
            (a, b) =>
                new Date(a.timestamp).getTime() -
                new Date(b.timestamp).getTime(),
        );
        const firstData = sortedData[0];
        const lastData = sortedData[sortedData.length - 1];
        if (!firstData || !lastData) return null;

        const firstDate = new Date(firstData.timestamp);
        const lastDate = new Date(lastData.timestamp);
        const diffTime = Math.abs(lastDate.getTime() - firstDate.getTime());
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
        const monthYear = firstDate.toLocaleDateString("en-US", {
            month: "long",
            year: "numeric",
        });

        return { monthYear, diffDays };
    }, [mapPhotos]);

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
            sx={{
                position: "absolute",
                // Desktop: left sidebar taking 35% width
                left: { xs: 0, md: 16 },
                top: { xs: "auto", md: 16 },
                bottom: { xs: 0, md: 16 },
                right: { xs: 0, md: "auto" },
                width: { xs: "100%", md: "35%" },
                height: { xs: "40%", md: "auto" },
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
            }}
        >
            <Box ref={coverRef}>
                <MapCover
                    name={collectionSummary.name}
                    mapPhotos={mapPhotos}
                    coverImageUrl={coverImageUrl}
                    visibleCount={visibleCount}
                    onClose={onClose}
                />
            </Box>

            {/* Sticky header that appears when cover is scrolled out */}
            <Box
                sx={{
                    position: "sticky",
                    top: 0,
                    zIndex: 10,
                    bgcolor: (theme) => theme.vars.palette.background.paper,
                    px: { xs: "24px", md: "32px" },
                    pt: isCoverHidden ? 3.5 : 0,
                    pb: isCoverHidden ? 2 : 0,
                    display: isCoverHidden ? "flex" : "none",
                    justifyContent: "space-between",
                    alignItems: "center",
                    borderBottom: (theme) =>
                        `1px solid ${theme.palette.divider}`,
                }}
            >
                <Stack spacing={0.25}>
                    <Typography
                        variant="body"
                        sx={{ fontWeight: 600, lineHeight: 1.2 }}
                        noWrap
                    >
                        {collectionSummary.name}
                    </Typography>
                    <Typography variant="small" color="text.secondary">
                        {coverStats
                            ? `${coverStats.monthYear} • ${coverStats.diffDays} days • ${visibleCount} memories`
                            : `${visibleCount} memories`}
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
                }}
            >
                <PhotoList
                    photoGroups={photoGroups}
                    thumbByFileID={thumbByFileID}
                    visiblePhotoOrder={visiblePhotoOrder}
                    visiblePhotosWave={visiblePhotosWave}
                    onPhotoClick={onPhotoClick}
                    stickyHeaderVisible={isCoverHidden}
                />
            </Box>
        </Box>
    );
}

interface PhotoListProps {
    photoGroups: PhotoGroup[];
    thumbByFileID: Map<number, string>;
    visiblePhotoOrder: Map<number, number>;
    visiblePhotosWave: number;
    onPhotoClick: (fileId: number) => void;
    stickyHeaderVisible: boolean;
}

function PhotoList({
    photoGroups,
    thumbByFileID,
    visiblePhotoOrder,
    visiblePhotosWave,
    onPhotoClick,
    stickyHeaderVisible,
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
                    stickyHeaderVisible={stickyHeaderVisible}
                />
            ))}
        </Stack>
    );
}

interface PhotoDateGroupProps {
    dateLabel: string;
    photos: JourneyPoint[];
    thumbByFileID: Map<number, string>;
    visiblePhotoOrder: Map<number, number>;
    visiblePhotosWave: number;
    onPhotoClick: (fileId: number) => void;
    stickyHeaderVisible: boolean;
}

function PhotoDateGroup({
    dateLabel,
    photos,
    thumbByFileID,
    visiblePhotoOrder,
    visiblePhotosWave,
    onPhotoClick,
    stickyHeaderVisible,
}: PhotoDateGroupProps) {
    const [isStuck, setIsStuck] = useState(false);
    const sentinelRef = useRef<HTMLDivElement>(null);

    useEffect(() => {
        const sentinel = sentinelRef.current;
        if (!sentinel) return;

        const observer = new IntersectionObserver(
            ([entry]) => {
                // When sentinel is not visible (scrolled past), the header is stuck
                setIsStuck(entry ? !entry.isIntersecting : false);
            },
            { threshold: 0 },
        );

        observer.observe(sentinel);
        return () => observer.disconnect();
    }, []);

    // Offset for sticky header when visible
    const topOffset = stickyHeaderVisible ? "72px" : 0;

    return (
        <Stack spacing={0.75}>
            {/* Sentinel element to detect when sticky kicks in */}
            <Box ref={sentinelRef} sx={{ height: 0, visibility: "hidden" }} />
            <Box
                sx={{
                    position: "sticky",
                    top: topOffset,
                    bgcolor: (theme) => theme.vars.palette.background.paper,
                    zIndex: 2,
                    pt: isStuck ? 3 : 1.5,
                    pb: isStuck ? 2 : 1.5,
                    ml: { xs: "-24px", md: "-32px" },
                    mr: { xs: "-24px", md: "-32px" },
                    px: { xs: "0", md: "0" },
                    transition: "padding 0.15s ease-out, top 0.2s ease-out",
                }}
            >
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
}

// ============================================================================
// Map Components
// ============================================================================

interface MapCanvasProps {
    mapComponents: MapComponents;
    mapCenter: [number, number];
    mapPhotos: JourneyPoint[];
    optimalZoom: number;
    thumbByFileID: Map<number, string>;
    createClusterCustomIcon: (cluster: unknown) => unknown;
    onVisiblePhotosChange: (photosInView: JourneyPoint[]) => void;
}

function MapCanvas({
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
                        icon={
                            createIcon(
                                thumbByFileID.get(photo.fileId) ?? photo.image,
                                68,
                                "#f6f6f6",
                                undefined,
                                false,
                            ) ?? undefined
                        }
                    />
                ))}
            </MarkerClusterGroup>
        </MapContainer>
    );
}

interface MapControlsProps {
    useMap: typeof import("react-leaflet").useMap;
}

function MapControls({ useMap }: MapControlsProps) {
    const map = useMap();

    const handleOpenInMaps = () => {
        const center = map.getCenter();
        const url = `https://www.google.com/maps?q=${center.lat},${center.lng}&z=${map.getZoom()}`;
        window.open(url, "_blank", "noopener,noreferrer");
    };

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
                <FloatingIconButton onClick={() => map.zoomIn()}>
                    <AddIcon />
                </FloatingIconButton>
                <FloatingIconButton onClick={() => map.zoomOut()}>
                    <RemoveIcon />
                </FloatingIconButton>
            </Stack>
        </>
    );
}

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
    const previousVisibleIds = useRef<string | null>(null);
    const previousClusterCount = useRef<number | null>(null);

    const getClusterCount = useCallback(
        () => map.getContainer().querySelectorAll(".marker-cluster").length,
        [map],
    );

    const updateVisiblePhotos = useCallback(() => {
        const bounds = map.getBounds();
        const inView = photos.filter((p) => bounds.contains([p.lat, p.lng]));

        const idsSignature = inView
            .map((p) => p.fileId)
            .sort((a, b) => a - b)
            .join(",");

        const clusterCount = getClusterCount();
        const clusterChanged = previousClusterCount.current !== clusterCount;

        if (previousVisibleIds.current === idsSignature && !clusterChanged) {
            return;
        }

        previousVisibleIds.current = idsSignature;
        previousClusterCount.current = clusterCount;
        onVisiblePhotosChange(inView);
    }, [getClusterCount, map, onVisiblePhotosChange, photos]);

    useEffect(() => {
        if (!photos.length) {
            previousVisibleIds.current = "";
            previousClusterCount.current = getClusterCount();
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

interface MapCoverProps {
    name: string;
    mapPhotos: JourneyPoint[];
    coverImageUrl: string | undefined;
    visibleCount: number;
    onClose: () => void;
}

function MapCover({
    name,
    mapPhotos,
    coverImageUrl,
    visibleCount,
    onClose,
}: MapCoverProps) {
    const coverStats = useMemo(() => {
        if (!mapPhotos.length) return null;

        const sortedData = [...mapPhotos].sort(
            (a, b) =>
                new Date(a.timestamp).getTime() -
                new Date(b.timestamp).getTime(),
        );
        const firstData = sortedData[0];
        const lastData = sortedData[sortedData.length - 1];
        if (!firstData || !lastData) return null;

        const firstDate = new Date(firstData.timestamp);
        const lastDate = new Date(lastData.timestamp);
        const diffTime = Math.abs(lastDate.getTime() - firstDate.getTime());
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
        const monthYear = firstDate.toLocaleDateString("en-US", {
            month: "long",
            year: "numeric",
        });

        // Count unique locations based on lat/lng
        const uniqueLocations = new Set(
            mapPhotos.map(
                (point) => `${point.lat.toFixed(3)},${point.lng.toFixed(3)}`,
            ),
        );
        const locationCount = uniqueLocations.size;

        return { monthYear, diffDays, locationCount };
    }, [mapPhotos]);

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
                    {coverImageUrl && coverStats ? (
                        <>
                            <CoverTitle>{name}</CoverTitle>
                            <CoverSubtitle>
                                {coverStats.monthYear} • {coverStats.diffDays}{" "}
                                days • {visibleCount} memories
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
}

const CoverContainer = styled(Box)({
    width: "100%",
    flexShrink: 0,
    padding: "16px",
    paddingBottom: "8px",
});

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

interface ThumbImageProps {
    src: string | undefined;
    onClick: () => void;
    animationDelay: number;
}

function ThumbImage({ src, onClick, animationDelay }: ThumbImageProps) {
    const baseSx = {
        width: "100%",
        aspectRatio: "1",
        borderRadius: 0,
        border: (theme: { palette: { divider: string } }) =>
            `1px solid ${theme.palette.divider}`,
        opacity: 0,
        transformOrigin: "top left",
        animation: `${cascadeFadeIn} 200ms ease-out forwards`,
        animationDelay: `${animationDelay}ms`,
    };

    if (!src) {
        return (
            <Box
                sx={{
                    ...baseSx,
                    bgcolor: (theme) => theme.vars.palette.fill.faint,
                }}
            />
        );
    }

    return (
        <Box
            component="img"
            src={src}
            alt=""
            onClick={onClick}
            sx={{
                ...baseSx,
                objectFit: "cover",
                cursor: "pointer",
                transition: "transform 0.15s ease-in-out",
                "&:hover": { transform: "scale(1.02)" },
            }}
        />
    );
}
