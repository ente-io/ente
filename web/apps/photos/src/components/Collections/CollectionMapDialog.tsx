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
    Stack,
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
                mapPhotosCount={mapPhotos.length}
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
    mapPhotosCount: number;
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
    thumbByFileID,
    visiblePhotoOrder,
    visiblePhotosWave,
    onPhotoClick,
    onClose,
}: CollectionSidebarProps) {
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
                px: { xs: "24px", md: "32px" },
                pb: { xs: "24px", md: "32px" },
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
            <SidebarHeader
                name={collectionSummary.name}
                visibleCount={visibleCount}
                onClose={onClose}
            />
            <PhotoList
                photoGroups={photoGroups}
                thumbByFileID={thumbByFileID}
                visiblePhotoOrder={visiblePhotoOrder}
                visiblePhotosWave={visiblePhotosWave}
                onPhotoClick={onPhotoClick}
            />
        </Box>
    );
}

interface SidebarHeaderProps {
    name: string;
    visibleCount: number;
    onClose: () => void;
}

function SidebarHeader({ name, visibleCount, onClose }: SidebarHeaderProps) {
    return (
        <Box
            sx={{
                position: "sticky",
                top: { xs: "0", md: "0" },
                mx: { xs: "-24px", md: "-32px" },
                px: { xs: "24px", md: "32px" },
                pt: { xs: "24px", md: "32px" },
                pr: { md: "24px" },
                pb: 2,
                bgcolor: (theme) => theme.vars.palette.background.paper,
                zIndex: 3,
                display: "flex",
                flexDirection: "row",
                justifyContent: "space-between",
            }}
        >
            <Stack>
                <Typography variant="h5" sx={{ fontWeight: 700 }} noWrap>
                    {name}
                </Typography>
                <Typography
                    variant="body"
                    color="text.secondary"
                    sx={{
                        mt: 0.25,
                        display: "flex",
                        alignItems: "center",
                        gap: 0.5,
                    }}
                >
                    {visibleCount} {t("memories", { defaultValue: "memories" })}
                </Typography>
            </Stack>
            <IconButton
                aria-label={t("close")}
                onClick={onClose}
                sx={{ bgcolor: "rgba(255, 255, 255, 0.1)" }}
            >
                <CloseIcon />
            </IconButton>
        </Box>
    );
}

interface PhotoListProps {
    photoGroups: PhotoGroup[];
    thumbByFileID: Map<number, string>;
    visiblePhotoOrder: Map<number, number>;
    visiblePhotosWave: number;
    onPhotoClick: (fileId: number) => void;
}

function PhotoList({
    photoGroups,
    thumbByFileID,
    visiblePhotoOrder,
    visiblePhotosWave,
    onPhotoClick,
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
}

function PhotoDateGroup({
    dateLabel,
    photos,
    thumbByFileID,
    visiblePhotoOrder,
    visiblePhotosWave,
    onPhotoClick,
}: PhotoDateGroupProps) {
    return (
        <Stack spacing={0.75}>
            <Box
                sx={{
                    position: "sticky",
                    top: { xs: "56px", md: "85px" },
                    bgcolor: (theme) => theme.vars.palette.background.paper,
                    zIndex: 2,
                    py: 1.5,
                    ml: { xs: "-24px", md: "-32px" },
                    mr: { xs: "-24px", md: "-32px" },
                    px: { xs: "0", md: "0" },
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
                    sx={{
                        position: "absolute",
                        top: 16,
                        right: 16,
                        bgcolor: (theme) => theme.vars.palette.background.paper,
                        boxShadow: (theme) => theme.shadows[2],
                    }}
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
