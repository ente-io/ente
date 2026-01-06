import AddIcon from "@mui/icons-material/Add";
import CloseIcon from "@mui/icons-material/Close";
import InfoOutlinedIcon from "@mui/icons-material/InfoOutlined";
import LocationOnIcon from "@mui/icons-material/LocationOn";
import RemoveIcon from "@mui/icons-material/Remove";
import {
    Box,
    Dialog,
    DialogContent,
    IconButton,
    Stack,
    styled,
    Typography,
    useMediaQuery,
    type IconButtonProps,
} from "@mui/material";
import { useTheme } from "@mui/material/styles";
import { ensureLocalUser } from "ente-accounts/services/user";
import { ActivityIndicator } from "ente-base/components/mui/ActivityIndicator";
import type { ModalVisibilityProps } from "ente-base/components/utils/modal";
import { useBaseContext } from "ente-base/context";
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
import type { RemotePullOpts } from "ente-new/photos/components/gallery";
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
import "leaflet.markercluster/dist/MarkerCluster.css";
import "leaflet.markercluster/dist/MarkerCluster.Default.css";
import "leaflet/dist/leaflet.css";
import type { Dispatch, SetStateAction } from "react";
import React, {
    useCallback,
    useEffect,
    useMemo,
    useRef,
    useState,
} from "react";
import type { SelectedState } from "utils/file";
import type { FileListWithViewerProps } from "../FileListWithViewer";
import { FileListWithViewer } from "../FileListWithViewer";
import { calculateOptimalZoom, getMapCenter } from "../TripLayout/mapHelpers";
import type { JourneyPoint } from "../TripLayout/types";
import { generateNeededThumbnails } from "../TripLayout/utils/dataProcessing";

// ============================================================================
// Types
// ============================================================================

interface CollectionMapDialogProps
    extends ModalVisibilityProps,
        Pick<
            FileListWithViewerProps,
            | "onAddSaveGroup"
            | "onMarkTempDeleted"
            | "onAddFileToCollection"
            | "onRemoteFilesPull"
            | "onVisualFeedback"
            | "fileNormalCollectionIDs"
            | "collectionNameByID"
            | "onSelectCollection"
            | "onSelectPerson"
        > {
    collectionSummary: CollectionSummary;
    activeCollection: Collection | undefined;
    onRemotePull?: (opts?: RemotePullOpts) => Promise<void>;
}

interface MapDataState {
    mapCenter: [number, number] | null;
    mapPhotos: JourneyPoint[];
    filesByID: Map<number, EnteFile>;
    thumbByFileID: Map<number, string>;
    isLoading: boolean;
    error: string | null;
}

interface FavoritesState {
    favoriteFileIDs: Set<number>;
    pendingFavoriteUpdates: Set<number>;
    pendingVisibilityUpdates: Set<number>;
}

interface MapDataResult extends MapDataState {
    removeFiles: (fileIDs: number[]) => void;
    updateFileVisibility: (file: EnteFile, visibility: ItemVisibility) => void;
}

/**
 * Dynamically loaded map components to avoid SSR issues with Leaflet
 */
interface MapComponents {
    MapContainer: typeof import("react-leaflet").MapContainer;
    TileLayer: typeof import("react-leaflet").TileLayer;
    Marker: typeof import("react-leaflet").Marker;
    useMap: typeof import("react-leaflet").useMap;
    MarkerClusterGroup: typeof import("react-leaflet-cluster").default;
}

// ============================================================================
// Custom Hooks
// ============================================================================

/**
 * Dynamically loads map-related React components (Leaflet) to avoid SSR issues
 * Responsibility: Lazy load map dependencies only when needed (window must exist)
 */
function useMapComponents() {
    const [mapComponents, setMapComponents] = useState<MapComponents | null>(
        null,
    );

    useEffect(() => {
        // Only load on client-side where window exists
        if (typeof window === "undefined") return;

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
 * Loads and manages map data including photos, locations, and thumbnails
 * Responsibility: Fetch collection files, extract locations, generate thumbnails
 */
function useMapData(
    open: boolean,
    collectionSummary: CollectionSummary,
    activeCollection: Collection | undefined,
    onGenericError: (e: unknown) => void,
): MapDataResult {
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
                const files = await getFilesForCollection(
                    collectionSummary,
                    activeCollection,
                );
                const locationPoints = extractLocationPoints(files); // transforms the files into JourneyData[]

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
                    return;
                }

                // Reset state when no geotagged locations exist to avoid showing stale data
                setState({
                    filesByID: new Map(),
                    mapCenter: null,
                    mapPhotos: [],
                    thumbByFileID: new Map(),
                    isLoading: false,
                    error: null,
                });

                return;
            } catch (e) {
                setState((prev) => ({
                    ...prev,
                    isLoading: false,
                    error: t("something_went_wrong"),
                }));
                onGenericError(e);
            } finally {
                // Ensure we never leave the dialog stuck in a loading state
                setState((prev) =>
                    prev.isLoading ? { ...prev, isLoading: false } : prev,
                );
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

    const removeFiles = useCallback((fileIDs: number[]) => {
        if (!fileIDs.length) return;
        setState((prev) => {
            const ids = new Set(fileIDs);
            const filesByID = new Map(prev.filesByID);
            const thumbByFileID = new Map(prev.thumbByFileID);
            ids.forEach((id) => {
                filesByID.delete(id);
                thumbByFileID.delete(id);
            });
            const mapPhotos = prev.mapPhotos.filter(
                (photo) => !ids.has(photo.fileId),
            );
            return {
                ...prev,
                filesByID,
                thumbByFileID,
                mapPhotos,
                mapCenter: mapPhotos.length ? prev.mapCenter : null,
            };
        });
    }, []);

    const updateFileVisibility = useCallback(
        (file: EnteFile, visibility: ItemVisibility) => {
            setState((prev) => {
                if (!prev.filesByID.has(file.id)) return prev;
                if (!file.magicMetadata) return prev;

                const updatedMagicMetadata = {
                    ...file.magicMetadata,
                    data: { ...file.magicMetadata.data, visibility },
                };

                const updatedFile: EnteFile = {
                    ...file,
                    magicMetadata: updatedMagicMetadata,
                };
                const filesByID = new Map(prev.filesByID);
                filesByID.set(file.id, updatedFile);
                return { ...prev, filesByID };
            });
        },
        [],
    );

    return { ...state, removeFiles, updateFileVisibility };
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
    const addToSet = useCallback((set: Set<number>, id: number) => {
        if (set.has(id)) return set;
        const next = new Set(set);
        next.add(id);
        return next;
    }, []);

    const removeFromSet = useCallback((set: Set<number>, id: number) => {
        if (!set.has(id)) return set;
        const next = new Set(set);
        next.delete(id);
        return next;
    }, []);

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
                setPendingFavoriteUpdates((prev) =>
                    removeFromSet(prev, fileID),
                );
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
 * Manages the lifecycle of the currently visible journey photos.
 *
 * Tracks the ordered list of visible photos and exposes a setter to update them.
 *
 * @returns An object containing the visible photos array and setter.
 */
function useVisiblePhotos() {
    const [visiblePhotos, setVisiblePhotos] = useState<JourneyPoint[]>([]);

    return { visiblePhotos, setVisiblePhotos };
}

/**
 * Creates a marker icon for individual photos (no badge)
 * Used only in CollectionMapDialog for consistent styling
 */
function createMarkerIcon(
    imageSrc: string,
    size: number,
): import("leaflet").DivIcon | null {
    if (typeof window === "undefined") return null;

    // eslint-disable-next-line @typescript-eslint/no-require-imports
    const leaflet = require("leaflet") as typeof import("leaflet");

    const pinSize = size + 16; // Add padding for consistent sizing with TripLayout
    const triangleHeight = 10;
    const pinHeight = pinSize + triangleHeight + 2;
    const hasImage = imageSrc && imageSrc.trim() !== "";

    // Border radius matching TripLayout style
    const outerBorderRadius = 16;
    const innerBorderRadius = 12;

    return leaflet.divIcon({
        html: `
            <div class="photo-pin" style="
                width: ${pinSize}px;
                height: ${pinHeight}px;
                position: relative;
                cursor: pointer;
                transition: all 0.3s ease;
                filter: drop-shadow(0 4px 8px rgba(0, 0, 0, 0.3)) drop-shadow(0 2px 4px rgba(0, 0, 0, 0.2));
            ">
              <div style="
                  width: ${pinSize}px;
                  height: ${pinSize}px;
                  border-radius: ${outerBorderRadius}px;
                  background: white;
                  border: 2px solid #ffffff;
                  padding: 4px;
                  position: relative;
                  overflow: hidden;
                  transition: background-color 0.3s ease, border-color 0.3s ease;
              "
              onmouseover="this.style.background='#22c55e'; this.style.borderColor='#22c55e'; this.nextElementSibling.style.borderTopColor='#22c55e';"
              onmouseout="this.style.background='white'; this.style.borderColor='#ffffff'; this.nextElementSibling.style.borderTopColor='white';"
              >
                ${
                    hasImage
                        ? `<img src="${imageSrc}" style="width:100%;height:100%;object-fit:cover;border-radius:${innerBorderRadius}px;" alt="Location" />`
                        : `<div style="width:100%;height:100%;border-radius:${innerBorderRadius}px;animation:skeleton-pulse 1.5s ease-in-out infinite;"></div>
                           <style>@keyframes skeleton-pulse{0%{background-color:#ffffff}50%{background-color:#f0f0f0}100%{background-color:#ffffff}}</style>`
                }
              </div>
              <div style="
                  position: absolute;
                  bottom: 2px;
                  left: 50%;
                  transform: translateX(-50%);
                  width: 0;
                  height: 0;
                  border-left: ${triangleHeight}px solid transparent;
                  border-right: ${triangleHeight}px solid transparent;
                  border-top: ${triangleHeight}px solid white;
                  transition: border-top-color 0.3s ease;
              "></div>
            </div>
        `,
        className: "collection-marker",
        iconSize: [pinSize, pinHeight],
        iconAnchor: [pinSize / 2, pinHeight],
        popupAnchor: [0, -pinHeight],
    });
}

/**
 * Creates a cluster icon with badge popping out of the container
 * Used only in CollectionMapDialog for cluster markers
 */
function createClusterIcon(
    imageSrc: string,
    size: number,
    clusterCount: number,
): import("leaflet").DivIcon | null {
    if (typeof window === "undefined") return null;

    // eslint-disable-next-line @typescript-eslint/no-require-imports
    const leaflet = require("leaflet") as typeof import("leaflet");

    const pinSize = size + 16; // Add padding for consistent sizing with TripLayout
    const triangleHeight = 10;
    const pinHeight = pinSize + triangleHeight + 2;
    const hasImage = imageSrc && imageSrc.trim() !== "";
    const badgeOverflow = 6;

    // Border radius matching TripLayout style
    const outerBorderRadius = 16;
    const innerBorderRadius = 12;

    const badgeLabel =
        clusterCount >= 2000
            ? `${Math.floor((clusterCount - 1) / 1000)}K+`
            : clusterCount >= 1000
              ? "1K+"
              : clusterCount > 999
                ? `${Math.floor(clusterCount / 100)}00+`
                : `${clusterCount}`;

    return leaflet.divIcon({
        html: `
            <div class="photo-pin" style="
                width: ${pinSize}px;
                height: ${pinHeight}px;
                position: relative;
                cursor: pointer;
                transition: all 0.3s ease;
                overflow: visible;
                filter: drop-shadow(0 4px 8px rgba(0, 0, 0, 0.3)) drop-shadow(0 2px 4px rgba(0, 0, 0, 0.2));
            ">
              <div style="
                  width: ${pinSize}px;
                  height: ${pinSize}px;
                  border-radius: ${outerBorderRadius}px;
                  background: white;
                  border: 2px solid #ffffff;
                  padding: 4px;
                  position: relative;
                  overflow: hidden;
                  transition: background-color 0.3s ease, border-color 0.3s ease;
              "
              onmouseover="this.style.background='#22c55e'; this.style.borderColor='#22c55e'; this.parentElement.querySelector('.triangle').style.borderTopColor='#22c55e';"
              onmouseout="this.style.background='white'; this.style.borderColor='#ffffff'; this.parentElement.querySelector('.triangle').style.borderTopColor='white';"
              >
                ${
                    hasImage
                        ? `<img src="${imageSrc}" style="width:100%;height:100%;object-fit:cover;border-radius:${innerBorderRadius}px;" alt="Location" />`
                        : `<div style="width:100%;height:100%;border-radius:${innerBorderRadius}px;animation:skeleton-pulse 1.5s ease-in-out infinite;"></div>
                           <style>@keyframes skeleton-pulse{0%{background-color:#ffffff}50%{background-color:#f0f0f0}100%{background-color:#ffffff}}</style>`
                }
              </div>
              <div style="
                  position: absolute;
                  top: -${badgeOverflow}px;
                  right: -${badgeOverflow}px;
                  background: #22c55e;
                  color: #ffffff;
                  border-radius: 7px;
                  padding: 4px 7px;
                  font-size: 12px;
                  font-weight: 700;
                  line-height: 1;
                  box-shadow: 0 2px 6px rgba(0,0,0,0.2);
                  z-index: 1;
              ">
                  ${badgeLabel}
              </div>
              <style>
                .leaflet-marker-icon.collection-cluster-marker { overflow: visible !important; }
              </style>
              <div class="triangle" style="
                  position: absolute;
                  bottom: 2px;
                  left: 50%;
                  transform: translateX(-50%);
                  width: 0;
                  height: 0;
                  border-left: ${triangleHeight}px solid transparent;
                  border-right: ${triangleHeight}px solid transparent;
                  border-top: ${triangleHeight}px solid white;
                  transition: border-top-color 0.3s ease;
              "></div>
            </div>
        `,
        className: "collection-cluster-marker",
        iconSize: [pinSize + badgeOverflow, pinHeight + badgeOverflow],
        iconAnchor: [pinSize / 2, pinHeight],
        popupAnchor: [0, -pinHeight],
    });
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
            const count: number = cluster.getChildCount();
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

            return createClusterIcon(thumbnailUrl, 68, count);
        },
        [photosByPosition, thumbByFileID],
    );
}

// ============================================================================
// Helper Functions
// ============================================================================

/**
 * Extracts thumbnail URL - prioritizes photo.image (loaded first with mapPhotos),
 * then falls back to thumbByFileID (loaded afterward with higher quality thumbs)
 */
function getPhotoThumbnail(
    photo: JourneyPoint,
    thumbByFileID: Map<number, string>,
): string | undefined {
    return photo.image || thumbByFileID.get(photo.fileId);
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
 * Returns true if the file is visible (not archived or hidden).
 */
function isFileVisible(file: EnteFile): boolean {
    const visibility = file.magicMetadata?.data.visibility;
    // Files without visibility metadata are considered visible (default state)
    return visibility === undefined || visibility === ItemVisibility.visible;
}

/**
 * Loads every file stored in IndexedDB, filters those belonging to the
 * target collection, removes duplicates by ID, filters out hidden/archived
 * files, and returns the unique set of visible files.
 */
async function getFilesForCollection(
    collectionSummary: CollectionSummary,
    activeCollection: Collection | undefined,
): Promise<EnteFile[]> {
    const allFiles = await savedCollectionFiles();
    // Filter out hidden and archived files to prevent leaking items users expect to remain hidden
    const visibleFiles = allFiles.filter(isFileVisible);

    if (collectionSummary.type === "all") {
        return uniqueFilesByID(visibleFiles);
    }
    if (!activeCollection) {
        return [];
    }
    const filtered = visibleFiles.filter(
        (file) => file.collectionID === activeCollection.id,
    );
    return uniqueFilesByID(filtered);
}

function extractLocationPoints(files: EnteFile[]): JourneyPoint[] {
    const points: JourneyPoint[] = [];

    for (const file of files) {
        const loc = fileLocation(file);
        if (!loc) continue;
        if (loc.latitude === 0 && loc.longitude === 0) continue; // Ignore invalid default coordinates

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
    onRemotePull,
    onAddSaveGroup,
    onMarkTempDeleted,
    onAddFileToCollection,
    onRemoteFilesPull,
    onVisualFeedback,
    fileNormalCollectionIDs,
    collectionNameByID,
    onSelectCollection,
    onSelectPerson,
}) => {
    const { onGenericError } = useBaseContext();
    const mapComponents = useMapComponents();
    const user = useCurrentUser();
    const [isFileViewerOpen, setIsFileViewerOpen] = useState(false);
    const optimalZoom = calculateOptimalZoom();

    const {
        mapCenter,
        mapPhotos,
        filesByID,
        thumbByFileID,
        isLoading,
        error,
        removeFiles: removeFilesFromMap,
        updateFileVisibility,
    } = useMapData(open, collectionSummary, activeCollection, onGenericError);

    const { visiblePhotos, setVisiblePhotos } = useVisiblePhotos();

    const {
        favoriteFileIDs,
        pendingFavoriteUpdates,
        pendingVisibilityUpdates,
        handleToggleFavorite,
        handleFileVisibilityUpdate,
    } = useFavorites(open, user);

    const createClusterCustomIcon = useClusterIcon(mapPhotos, thumbByFileID);

    const handleSetFileViewerOpen: Dispatch<SetStateAction<boolean>> =
        useCallback(
            (next) => {
                const nextValue =
                    typeof next === "function"
                        ? (next as (prev: boolean) => boolean)(isFileViewerOpen)
                        : next;
                setIsFileViewerOpen(nextValue);
            },
            [isFileViewerOpen],
        );

    // Convert visible JourneyPoints to EnteFiles for FileListWithViewer
    const visibleFiles = useMemo(() => {
        return visiblePhotos
            .map((p) => filesByID.get(p.fileId))
            .filter((f): f is EnteFile => f !== undefined);
    }, [visiblePhotos, filesByID]);

    const handleRemotePull = useCallback(
        () =>
            onRemotePull ? onRemotePull({ silent: true }) : Promise.resolve(),
        [onRemotePull],
    );
    const visualFeedback = useMemo(() => onVisualFeedback, [onVisualFeedback]);

    // Empty selection state since we don't support selection in map view
    const emptySelected = useMemo<SelectedState>(
        () => ({
            ownCount: 0,
            count: 0,
            context: undefined,
            collectionID: activeCollection?.id ?? collectionSummary.id,
        }),
        [activeCollection?.id, collectionSummary.id],
    );
    const noOpSetSelected = useCallback(() => {
        /* no-op */
    }, []);

    const handleMarkTempDeleted = useCallback(
        (files: EnteFile[]) => {
            onMarkTempDeleted?.(files);
            const idsToRemove = new Set(files.map((file) => file.id));
            setVisiblePhotos((prev) =>
                prev.filter((photo) => !idsToRemove.has(photo.fileId)),
            );
            removeFilesFromMap([...idsToRemove]);
        },
        [onMarkTempDeleted, removeFilesFromMap, setVisiblePhotos],
    );

    const handleFileVisibilityUpdateWithLocalState = useCallback(
        async (file: EnteFile, visibility: ItemVisibility) => {
            await handleFileVisibilityUpdate(file, visibility);
            const updatedMagicMetadata = file.magicMetadata
                ? {
                      ...file.magicMetadata,
                      data: { ...file.magicMetadata.data, visibility },
                  }
                : undefined;
            const updatedFile =
                updatedMagicMetadata !== undefined
                    ? { ...file, magicMetadata: updatedMagicMetadata }
                    : file;
            updateFileVisibility(updatedFile, visibility);
        },
        [handleFileVisibilityUpdate, updateFileVisibility],
    );

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

        // Wait for map components to load (they're dynamically imported)
        if (!mapComponents) {
            return (
                <CenteredBox>
                    <ActivityIndicator size="28px" />
                </CenteredBox>
            );
        }

        if (!mapPhotos.length || !mapCenter) {
            return (
                <CenteredBox onClose={onClose} closeLabel={t("close")}>
                    <Typography variant="body" color="text.secondary">
                        {t("no_geotagged_photos", {
                            defaultValue:
                                "No photos found with location information",
                        })}
                    </Typography>
                </CenteredBox>
            );
        }

        return (
            <MapLayout
                collectionSummary={collectionSummary}
                visiblePhotos={visiblePhotos}
                visibleFiles={visibleFiles}
                mapPhotos={mapPhotos}
                thumbByFileID={thumbByFileID}
                mapComponents={mapComponents}
                mapCenter={mapCenter}
                optimalZoom={optimalZoom}
                createClusterCustomIcon={createClusterCustomIcon}
                onClose={onClose}
                onVisiblePhotosChange={setVisiblePhotos}
                user={user}
                favoriteFileIDs={favoriteFileIDs}
                pendingFavoriteUpdates={pendingFavoriteUpdates}
                pendingVisibilityUpdates={pendingVisibilityUpdates}
                onToggleFavorite={handleToggleFavorite}
                onFileVisibilityUpdate={
                    handleFileVisibilityUpdateWithLocalState
                }
                onRemotePull={handleRemotePull}
                onVisualFeedback={visualFeedback}
                onAddSaveGroup={onAddSaveGroup}
                onMarkTempDeleted={handleMarkTempDeleted}
                onAddFileToCollection={onAddFileToCollection}
                onRemoteFilesPull={onRemoteFilesPull}
                fileNormalCollectionIDs={fileNormalCollectionIDs}
                collectionNameByID={collectionNameByID}
                onSelectCollection={onSelectCollection}
                onSelectPerson={onSelectPerson}
                selected={emptySelected}
                setSelected={noOpSetSelected}
                onSetOpenFileViewer={handleSetFileViewerOpen}
            />
        );
    }, [
        collectionSummary,
        createClusterCustomIcon,
        emptySelected,
        error,
        favoriteFileIDs,
        handleFileVisibilityUpdateWithLocalState,
        handleRemotePull,
        handleToggleFavorite,
        visualFeedback,
        isLoading,
        mapCenter,
        mapComponents,
        mapPhotos,
        noOpSetSelected,
        optimalZoom,
        onAddFileToCollection,
        onAddSaveGroup,
        onRemoteFilesPull,
        pendingFavoriteUpdates,
        pendingVisibilityUpdates,
        setVisiblePhotos,
        collectionNameByID,
        fileNormalCollectionIDs,
        handleMarkTempDeleted,
        onSelectCollection,
        onSelectPerson,
        thumbByFileID,
        user,
        visibleFiles,
        visiblePhotos,
        onClose,
        handleSetFileViewerOpen,
    ]);

    return (
        <Dialog
            fullScreen
            keepMounted
            open={open}
            onClose={onClose}
            sx={{
                // When the FileViewer is open, lower this dialog's z-index below
                // PhotoSwipe's z-index (1199) so that FileViewer appears on top.
                // This avoids the visual glitch caused by closing/reopening the
                // dialog during transitions.
                ...(isFileViewerOpen && {
                    zIndex: (theme) =>
                        `calc(${theme.zIndex.drawer} - 2) !important`,
                }),
            }}
        >
            <Box
                sx={{
                    position: "relative",
                    width: "100vw",
                    height: "100vh",
                    bgcolor: "background.default",
                }}
            >
                <DialogContent sx={{ padding: "0 !important", height: "100%" }}>
                    {body}
                </DialogContent>
            </Box>
        </Dialog>
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
    visibleFiles: EnteFile[];
    mapPhotos: JourneyPoint[];
    thumbByFileID: Map<number, string>;
    mapComponents: MapComponents;
    mapCenter: [number, number];
    optimalZoom: number;
    createClusterCustomIcon: (cluster: unknown) => unknown;
    onClose: () => void;
    onVisiblePhotosChange: (photosInView: JourneyPoint[]) => void;
    user: ReturnType<typeof useCurrentUser>;
    favoriteFileIDs: Set<number>;
    pendingFavoriteUpdates: Set<number>;
    pendingVisibilityUpdates: Set<number>;
    onToggleFavorite: (file: EnteFile) => Promise<void>;
    onFileVisibilityUpdate: (
        file: EnteFile,
        visibility: ItemVisibility,
    ) => Promise<void>;
    onRemotePull: () => Promise<void>;
    onVisualFeedback: () => void;
    onAddSaveGroup: FileListWithViewerProps["onAddSaveGroup"];
    onMarkTempDeleted?: FileListWithViewerProps["onMarkTempDeleted"];
    onAddFileToCollection?: FileListWithViewerProps["onAddFileToCollection"];
    onRemoteFilesPull?: FileListWithViewerProps["onRemoteFilesPull"];
    fileNormalCollectionIDs?: FileListWithViewerProps["fileNormalCollectionIDs"];
    collectionNameByID?: FileListWithViewerProps["collectionNameByID"];
    onSelectCollection?: FileListWithViewerProps["onSelectCollection"];
    onSelectPerson?: FileListWithViewerProps["onSelectPerson"];
    onSetOpenFileViewer?: (open: boolean) => void;
    selected: SelectedState;
    setSelected: () => void;
}

function MapLayout({
    collectionSummary,
    visiblePhotos,
    visibleFiles,
    mapPhotos,
    thumbByFileID,
    mapComponents,
    mapCenter,
    optimalZoom,
    createClusterCustomIcon,
    onClose,
    onVisiblePhotosChange,
    user,
    favoriteFileIDs,
    pendingFavoriteUpdates,
    pendingVisibilityUpdates,
    onToggleFavorite,
    onFileVisibilityUpdate,
    onRemotePull,
    onVisualFeedback,
    onAddSaveGroup,
    onMarkTempDeleted,
    onAddFileToCollection,
    onRemoteFilesPull,
    fileNormalCollectionIDs,
    collectionNameByID,
    onSelectCollection,
    onSelectPerson,
    onSetOpenFileViewer,
    selected,
    setSelected,
}: MapLayoutProps) {
    return (
        <Box sx={{ position: "relative", height: "100%", width: "100%" }}>
            <CollectionSidebar
                collectionSummary={collectionSummary}
                visibleCount={visiblePhotos.length}
                visibleFiles={visibleFiles}
                mapPhotos={mapPhotos}
                thumbByFileID={thumbByFileID}
                onClose={onClose}
                user={user}
                favoriteFileIDs={favoriteFileIDs}
                pendingFavoriteUpdates={pendingFavoriteUpdates}
                pendingVisibilityUpdates={pendingVisibilityUpdates}
                onToggleFavorite={onToggleFavorite}
                onFileVisibilityUpdate={onFileVisibilityUpdate}
                onRemotePull={onRemotePull}
                onVisualFeedback={onVisualFeedback}
                onAddSaveGroup={onAddSaveGroup}
                onMarkTempDeleted={onMarkTempDeleted}
                onAddFileToCollection={onAddFileToCollection}
                onRemoteFilesPull={onRemoteFilesPull}
                fileNormalCollectionIDs={fileNormalCollectionIDs}
                collectionNameByID={collectionNameByID}
                onSelectCollection={onSelectCollection}
                onSelectPerson={onSelectPerson}
                selected={selected}
                setSelected={setSelected}
                onSetOpenFileViewer={onSetOpenFileViewer}
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
 * Sidebar displaying collection details and photo thumbnails using FileListWithViewer
 * Responsibility: Show collection cover, header, and file list with integrated viewer
 */
interface CollectionSidebarProps {
    collectionSummary: CollectionSummary;
    visibleCount: number;
    visibleFiles: EnteFile[];
    mapPhotos: JourneyPoint[];
    thumbByFileID: Map<number, string>;
    onClose: () => void;
    user: ReturnType<typeof useCurrentUser>;
    favoriteFileIDs: Set<number>;
    pendingFavoriteUpdates: Set<number>;
    pendingVisibilityUpdates: Set<number>;
    onToggleFavorite: (file: EnteFile) => Promise<void>;
    onFileVisibilityUpdate: (
        file: EnteFile,
        visibility: ItemVisibility,
    ) => Promise<void>;
    onRemotePull: () => Promise<void>;
    onVisualFeedback: () => void;
    onAddSaveGroup: FileListWithViewerProps["onAddSaveGroup"];
    onMarkTempDeleted?: FileListWithViewerProps["onMarkTempDeleted"];
    onAddFileToCollection?: FileListWithViewerProps["onAddFileToCollection"];
    onRemoteFilesPull?: FileListWithViewerProps["onRemoteFilesPull"];
    fileNormalCollectionIDs?: FileListWithViewerProps["fileNormalCollectionIDs"];
    collectionNameByID?: FileListWithViewerProps["collectionNameByID"];
    onSelectCollection?: FileListWithViewerProps["onSelectCollection"];
    onSelectPerson?: FileListWithViewerProps["onSelectPerson"];
    onSetOpenFileViewer?: (open: boolean) => void;
    selected: SelectedState;
    setSelected: () => void;
}

// Fixed height for the cover image container (px)
const COVER_IMAGE_HEIGHT = 320;
// Mobile has less padding: 8px top + 12px bottom + 2px margin = 22px
// Desktop has more padding: 16px top + 16px bottom + 2px margin = 34px
// Use desktop value for consistency in the virtualized list
const COVER_HEADER_HEIGHT = COVER_IMAGE_HEIGHT + 34;

function CollectionSidebar({
    collectionSummary,
    visibleFiles,
    mapPhotos,
    thumbByFileID,
    onClose,
    user,
    favoriteFileIDs,
    pendingFavoriteUpdates,
    pendingVisibilityUpdates,
    onToggleFavorite,
    onFileVisibilityUpdate,
    onRemotePull,
    onVisualFeedback,
    onAddSaveGroup,
    onMarkTempDeleted,
    onAddFileToCollection,
    onRemoteFilesPull,
    fileNormalCollectionIDs,
    collectionNameByID,
    onSelectCollection,
    onSelectPerson,
    onSetOpenFileViewer,
    selected,
    setSelected,
}: CollectionSidebarProps) {
    const [currentDate, setCurrentDate] = useState<string | undefined>(
        undefined,
    );
    const [scrollOffset, setScrollOffset] = useState(0);
    const shouldShowCover = collectionSummary.type !== "all";
    const theme = useTheme();
    const isDarkMode = theme.palette.mode === "dark";
    const isMobile = useMediaQuery(theme.breakpoints.down("md"));

    // Get cover image: prioritize collection's coverFile, fallback to first photo
    const coverFile = collectionSummary.coverFile;
    const coverImageUrl = useMemo(() => {
        const coverThumb = coverFile && thumbByFileID.get(coverFile.id);
        if (coverThumb) return coverThumb;

        const fallbackPhoto = mapPhotos[0];
        return fallbackPhoto
            ? getPhotoThumbnail(fallbackPhoto, thumbByFileID)
            : undefined;
    }, [coverFile, mapPhotos, thumbByFileID]);

    // Create header component for FileListWithViewer (cover scrolls with content)
    const coverHeader = useMemo(() => {
        if (!shouldShowCover) return undefined;
        return {
            component: (
                <MapCover
                    name={collectionSummary.name}
                    coverImageUrl={coverImageUrl}
                    totalCount={collectionSummary.fileCount}
                    onClose={onClose}
                />
            ),
            height: COVER_HEADER_HEIGHT,
            extendToInlineEdges: true,
        };
    }, [
        shouldShowCover,
        collectionSummary.name,
        collectionSummary.fileCount,
        coverImageUrl,
        onClose,
    ]);

    // Handle scroll events from the file list
    const handleScroll = useCallback((offset: number) => {
        setScrollOffset(offset);
    }, []);

    // Handle visible date changes from the file list
    const handleVisibleDateChange = useCallback((date: string | undefined) => {
        setCurrentDate(date);
    }, []);

    // Only show sticky date after scrolling past the cover header, or always for "All"
    const showStickyHeader =
        !shouldShowCover ||
        (scrollOffset > COVER_HEADER_HEIGHT && !!currentDate);
    const hasScrolled = scrollOffset > 0;
    const hideDateForAllNoScroll = !shouldShowCover && !hasScrolled;
    const hideDateForMobileNoScroll = isMobile && !hasScrolled;
    const visibleDate =
        currentDate && !hideDateForAllNoScroll && !hideDateForMobileNoScroll
            ? currentDate
            : undefined;

    return (
        <SidebarWrapper>
            <SidebarContainer>
                <StickyDateHeader
                    visible={showStickyHeader}
                    variant={shouldShowCover ? "overlay" : "static"}
                >
                    <Box
                        sx={{
                            display: "flex",
                            justifyContent: "space-between",
                            alignItems: "center",
                        }}
                    >
                        <Box>
                            <Typography
                                variant="body"
                                sx={{ fontWeight: 700, fontSize: "18px" }}
                            >
                                {collectionSummary.name}
                            </Typography>
                            <Typography
                                variant="small"
                                sx={{ color: "text.muted", fontSize: "14px" }}
                            >
                                {collectionSummary.fileCount} memories
                                {visibleDate && ` · ${visibleDate}`}
                            </Typography>
                        </Box>
                        <IconButton
                            onClick={onClose}
                            size="small"
                            sx={{
                                color: "text.secondary",
                                bgcolor: "fill.faint",
                                "&:hover": { bgcolor: "fill.muted" },
                            }}
                        >
                            <CloseIcon />
                        </IconButton>
                    </Box>
                </StickyDateHeader>
                <FileListContainer>
                    {visibleFiles.length > 0 ? (
                        <FileListWithViewer
                            files={visibleFiles}
                            user={user}
                            favoriteFileIDs={favoriteFileIDs}
                            pendingFavoriteUpdates={pendingFavoriteUpdates}
                            pendingVisibilityUpdates={pendingVisibilityUpdates}
                            onToggleFavorite={onToggleFavorite}
                            onFileVisibilityUpdate={onFileVisibilityUpdate}
                            onRemotePull={onRemotePull}
                            onVisualFeedback={onVisualFeedback}
                            onAddSaveGroup={onAddSaveGroup}
                            onMarkTempDeleted={onMarkTempDeleted}
                            onAddFileToCollection={onAddFileToCollection}
                            onRemoteFilesPull={onRemoteFilesPull}
                            fileNormalCollectionIDs={fileNormalCollectionIDs}
                            collectionNameByID={collectionNameByID}
                            onSelectCollection={onSelectCollection}
                            onSelectPerson={onSelectPerson}
                            enableImageEditing={false}
                            enableDownload={true}
                            activeCollectionID={collectionSummary.id}
                            selected={selected}
                            setSelected={setSelected}
                            onSetOpenFileViewer={onSetOpenFileViewer}
                            listBorderRadius="0 0 32px 32px"
                            header={coverHeader}
                            onScroll={handleScroll}
                            onVisibleDateChange={handleVisibleDateChange}
                        />
                    ) : (
                        <EmptyState>
                            {shouldShowCover && (
                                <MapCover
                                    name={collectionSummary.name}
                                    coverImageUrl={coverImageUrl}
                                    totalCount={collectionSummary.fileCount}
                                    onClose={onClose}
                                />
                            )}
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
                    )}
                </FileListContainer>
            </SidebarContainer>
            {isDarkMode && <SidebarGradient />}
        </SidebarWrapper>
    );
}

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
        const icons = new Map<number, ReturnType<typeof createMarkerIcon>>();
        for (const photo of mapPhotos) {
            const thumbnail = getPhotoThumbnail(photo, thumbByFileID);
            icons.set(photo.fileId, createMarkerIcon(thumbnail ?? "", 68));
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
                attribution=""
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
                key={thumbByFileID.size}
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
                        key={`${photo.fileId}-${thumbByFileID.has(photo.fileId)}`}
                        position={[photo.lat, photo.lng]}
                        icon={markerIcons.get(photo.fileId) ?? undefined}
                    />
                ))}
            </MarkerClusterGroup>
        </MapContainer>
    );
});

/**
 * Floating map control buttons (open in Maps, zoom in/out, attribution)
 * Responsibility: Provide map navigation and external link controls
 */
interface MapControlsProps {
    useMap: typeof import("react-leaflet").useMap;
}

const MapControls = React.memo(function MapControls({
    useMap,
}: MapControlsProps) {
    const map = useMap();
    const [showAttribution, setShowAttribution] = useState(false);

    const handleOpenInMaps = useCallback(() => {
        const center = map.getCenter();
        const url = `https://www.google.com/maps?q=${center.lat},${center.lng}&z=${map.getZoom()}`;
        window.open(url, "_blank", "noopener,noreferrer");
    }, [map]);

    const handleZoomIn = useCallback(() => map.zoomIn(), [map]);
    const handleZoomOut = useCallback(() => map.zoomOut(), [map]);
    const toggleAttribution = useCallback(
        () => setShowAttribution((prev) => !prev),
        [],
    );

    return (
        <>
            <FloatingIconButton
                onClick={handleOpenInMaps}
                sx={{ position: "absolute", right: 16, top: 16, zIndex: 1000 }}
            >
                <LocationOnIcon />
            </FloatingIconButton>

            <Stack
                spacing={1}
                sx={(theme) => ({
                    position: "absolute",
                    left: 24,
                    top: 24,
                    zIndex: 1000,
                    [theme.breakpoints.up("md")]: {
                        left: "calc(24px + clamp(450px, 30vw, 600px) + 12px)",
                    },
                })}
            >
                <FloatingIconButton onClick={handleZoomIn}>
                    <AddIcon />
                </FloatingIconButton>
                <FloatingIconButton onClick={handleZoomOut}>
                    <RemoveIcon />
                </FloatingIconButton>
            </Stack>

            {/* Hide default Leaflet attribution watermark */}
            <style>{`.leaflet-control-attribution { display: none !important; }`}</style>

            {/* Desktop: Show attribution in bottom right corner */}
            <DesktopAttribution>
                <a
                    href="https://leafletjs.com"
                    target="_blank"
                    rel="noopener noreferrer"
                >
                    Leaflet
                </a>
                {" | © "}
                <a
                    href="https://www.openstreetmap.org/copyright"
                    target="_blank"
                    rel="noopener noreferrer"
                >
                    OpenStreetMap
                </a>
            </DesktopAttribution>

            {/* Mobile: Attribution info button */}
            <Box
                sx={(theme) => ({
                    position: "absolute",
                    left: 12,
                    bottom: 12,
                    zIndex: 1000,
                    [theme.breakpoints.up("md")]: { display: "none" },
                })}
            >
                {showAttribution && (
                    <AttributionPopup>
                        <Typography variant="mini" color="text.primary">
                            <a
                                href="https://leafletjs.com"
                                target="_blank"
                                rel="noopener noreferrer"
                                style={{ color: "inherit" }}
                            >
                                Leaflet
                            </a>
                            {" | © "}
                            <a
                                href="https://www.openstreetmap.org/copyright"
                                target="_blank"
                                rel="noopener noreferrer"
                                style={{ color: "inherit" }}
                            >
                                OpenStreetMap
                            </a>
                        </Typography>
                    </AttributionPopup>
                )}
                <IconButton
                    onClick={toggleAttribution}
                    size="small"
                    sx={{
                        width: 24,
                        height: 24,
                        opacity: 0.4,
                        "&:hover": { opacity: 0.7 },
                    }}
                >
                    <InfoOutlinedIcon sx={{ fontSize: 14, color: "#fff" }} />
                </IconButton>
            </Box>
        </>
    );
});

const DesktopAttribution = styled(Box)(({ theme }) => ({
    display: "none",
    [theme.breakpoints.up("md")]: {
        display: "block",
        position: "absolute",
        right: 8,
        bottom: 8,
        zIndex: 1000,
        backgroundColor: "rgba(255, 255, 255, 0.8)",
        padding: "2px 8px",
        borderRadius: "4px",
        fontSize: "11px",
        color: "#333",
        "& a": {
            color: "#0078A8",
            textDecoration: "none",
            "&:hover": { textDecoration: "underline" },
        },
    },
}));

const AttributionPopup = styled(Box)(({ theme }) => ({
    position: "absolute",
    bottom: 44,
    left: 0,
    backgroundColor: theme.vars.palette.background.paper,
    padding: "8px 12px",
    borderRadius: "8px",
    boxShadow: theme.shadows[4],
    whiteSpace: "nowrap",
    "& a": { textDecoration: "underline", "&:hover": { opacity: 0.8 } },
}));

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
        <CenteredBoxContainer>
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
        </CenteredBoxContainer>
    );
}

/**
 * Empty state placeholder for when no photos are visible
 * Responsibility: Display empty state message when no photos match filters
 */
function EmptyState({ children }: React.PropsWithChildren) {
    return <EmptyStateContainer>{children}</EmptyStateContainer>;
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
    totalCount: number;
    onClose: () => void;
}

const MapCover = React.memo(function MapCover({
    name,
    coverImageUrl,
    totalCount,
    onClose,
}: MapCoverProps) {
    return (
        <CoverContainer>
            <CoverImageContainer>
                <img
                    src={coverImageUrl}
                    alt="Cover"
                    style={{
                        position: "absolute",
                        inset: 0,
                        width: "100%",
                        height: "100%",
                        objectFit: "cover",
                        objectPosition: "Center",
                    }}
                />
                <CoverGradientOverlay />

                <CoverCloseButton aria-label="Close" onClick={onClose}>
                    <CloseIcon sx={{ fontSize: 20 }} />
                </CoverCloseButton>

                <CoverContentContainer>
                    <CoverTitle>{name}</CoverTitle>
                    <CoverSubtitle>{totalCount} memories</CoverSubtitle>
                </CoverContentContainer>
            </CoverImageContainer>
        </CoverContainer>
    );
});

const CoverContainer = styled(Box)(({ theme }) => ({
    width: "100%",
    flexShrink: 0,
    paddingTop: "16px",
    paddingBottom: "16px",
    [theme.breakpoints.down("md")]: {
        padding: "8px",
        paddingTop: "20px",
        paddingBottom: "12px",
    },
}));

const CoverImageContainer = styled(Box)(({ theme }) => ({
    height: `${COVER_IMAGE_HEIGHT}px`,
    position: "relative",
    overflow: "hidden",
    backgroundColor: "#333",
    borderRadius: "36px 36px 24px 24px",
    marginTop: "2px",
    [theme.breakpoints.down("md")]: { borderRadius: "20px 20px 20px 20px" },
}));

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
// Sidebar Styled Components
// ============================================================================

const SidebarWrapper = styled(Box)(({ theme }) => ({
    position: "absolute",
    left: 0,
    top: "auto",
    bottom: 0,
    right: 0,
    width: "100%",
    height: "50%",
    zIndex: 1000,
    [theme.breakpoints.up("md")]: {
        left: 16,
        top: 16,
        bottom: 16,
        right: "auto",
        height: "auto",
        width: "30%",
        maxWidth: "600px",
        minWidth: "450px",
    },
}));

const SidebarContainer = styled(Box)(({ theme }) => ({
    position: "relative",
    width: "100%",
    height: "100%",
    backgroundColor: theme.vars.palette.background.paper,
    boxShadow: theme.shadows[10],
    display: "flex",
    flexDirection: "column",
    overflow: "hidden",
    borderRadius: "24px 24px 0 0",
    [theme.breakpoints.up("md")]: { borderRadius: "48px" },
}));

const SidebarGradient = styled(Box)(({ theme }) => ({
    position: "absolute",
    bottom: 0,
    left: 0,
    right: 0,
    height: "80px",
    background:
        "linear-gradient(to top, rgba(0,0,0,1) 0%, rgba(0,0,0,0.65) 2%, rgba(0,0,0,0) 100%)",
    pointerEvents: "none",
    borderRadius: "0",
    [theme.breakpoints.up("md")]: {
        height: "150px",
        borderRadius: "0 0 48px 48px",
    },
}));

const FileListContainer = styled(Box)(({ theme }) => ({
    flex: 1,
    minHeight: 0,
    display: "flex",
    flexDirection: "column",
    paddingLeft: "8px",
    paddingRight: "8px",
    paddingTop: "0px",
    paddingBottom: "40px",
    [theme.breakpoints.up("md")]: {
        paddingTop: "0px",
        paddingLeft: "16px",
        paddingRight: "16px",
        paddingBottom: "18px",
    },
}));

const StickyDateHeader = styled(Box)<{
    visible: boolean;
    variant: "overlay" | "static";
}>(({ theme, visible, variant }) => {
    const isStatic = variant === "static";
    return {
        position: isStatic ? "relative" : "absolute",
        top: 0,
        left: 0,
        right: 0,
        zIndex: 10,
        backgroundColor: theme.vars.palette.background.paper,
        padding: "28px 24px 24px 24px",
        borderBottom: `1px solid ${theme.vars.palette.divider}`,
        opacity: isStatic || visible ? 1 : 0,
        transform: isStatic || visible ? "translateY(0)" : "translateY(-10px)",
        pointerEvents: isStatic || visible ? "auto" : "none",
        transition: isStatic
            ? "none"
            : "opacity 0.25s ease-out, transform 0.25s ease-out",
        [theme.breakpoints.down("md")]: { padding: "24px 20px 20px 20px" },
    };
});

const CenteredBoxContainer = styled(Box)({
    width: "100%",
    height: "100%",
    minHeight: "420px",
    position: "relative",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    gap: 8,
    flexDirection: "column",
    textAlign: "center",
});

const EmptyStateContainer = styled(Box)(({ theme }) => ({
    minHeight: "100%",
    display: "flex",
    flexDirection: "column",
    alignItems: "center",
    justifyContent: "center",
    textAlign: "center",
    paddingTop: 0,
    paddingBottom: theme.spacing(4),
    color: theme.vars.palette.text.secondary,
    gap: theme.spacing(1),
    overflow: "auto",
}));
