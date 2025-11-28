import { keyframes } from "@emotion/react";
import AddIcon from "@mui/icons-material/Add";
import ArrowBackIcon from "@mui/icons-material/ArrowBack";
import CloseIcon from "@mui/icons-material/Close";
import InfoOutlinedIcon from "@mui/icons-material/InfoOutlined";
import NavigationIcon from "@mui/icons-material/Navigation";
import RemoveIcon from "@mui/icons-material/Remove";
import {
    Box,
    Dialog,
    DialogContent,
    IconButton,
    Stack,
    Tooltip,
    Typography,
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
} from "ente-media/file-metadata";
import { findDefaultHiddenCollectionIDs } from "ente-new/photos/services/collection";
import { type CollectionSummary } from "ente-new/photos/services/collection-summary";
import {
    savedCollectionFiles,
    savedCollections,
} from "ente-new/photos/services/photos-fdb";
import { t } from "i18next";
import "leaflet/dist/leaflet.css";
import React, { useCallback, useEffect, useMemo, useState } from "react";
import {
    calculateOptimalZoom,
    createIcon,
    getMapCenter,
} from "../TripLayout/mapHelpers";
import type { JourneyPoint } from "../TripLayout/types";
import { generateNeededThumbnails } from "../TripLayout/utils/dataProcessing";

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

interface MapControlsProps {
    useMap: typeof import("react-leaflet").useMap;
    onClose: () => void;
}

const MapControls: React.FC<MapControlsProps> = ({ useMap, onClose }) => {
    const map = useMap();

    const handleZoomIn = () => {
        map.zoomIn();
    };

    const handleZoomOut = () => {
        map.zoomOut();
    };

    const handleOpenInMaps = () => {
        const center = map.getCenter();
        const url = `https://www.google.com/maps?q=${center.lat},${center.lng}&z=${map.getZoom()}`;
        window.open(url, "_blank", "noopener,noreferrer");
    };

    return (
        <>
            {/* Back button - Top Left */}
            <IconButton
                onClick={onClose}
                sx={{
                    position: "absolute",
                    left: 16,
                    top: 16,
                    zIndex: 1000,
                    bgcolor: (theme) => theme.vars.palette.background.paper,
                    boxShadow: (theme) => theme.shadows[4],
                    width: 48,
                    height: 48,
                    borderRadius: "16px",
                    transition: "transform 0.2s ease-out",
                    "&:hover": {
                        bgcolor: (theme) => theme.vars.palette.background.paper,
                        transform: "scale(1.05)",
                    },
                }}
            >
                <ArrowBackIcon />
            </IconButton>

            {/* Open in external map - Top Right */}
            <IconButton
                onClick={handleOpenInMaps}
                sx={{
                    position: "absolute",
                    right: 16,
                    top: 16,
                    zIndex: 1000,
                    bgcolor: (theme) => theme.vars.palette.background.paper,
                    boxShadow: (theme) => theme.shadows[4],
                    width: 48,
                    height: 48,
                    borderRadius: "16px",
                    transition: "transform 0.2s ease-out",
                    "&:hover": {
                        bgcolor: (theme) => theme.vars.palette.background.paper,
                        transform: "scale(1.05)",
                    },
                }}
            >
                <NavigationIcon />
            </IconButton>

            {/* Zoom controls - Bottom Right */}
            <Stack
                spacing={1}
                sx={{
                    position: "absolute",
                    right: 16,
                    bottom: 16,
                    zIndex: 1000,
                }}
            >
                <IconButton
                    onClick={handleZoomIn}
                    sx={{
                        bgcolor: (theme) => theme.vars.palette.background.paper,
                        boxShadow: (theme) => theme.shadows[4],
                        width: 48,
                        height: 48,
                        borderRadius: "16px",
                        transition: "transform 0.2s ease-out",
                        "&:hover": {
                            bgcolor: (theme) =>
                                theme.vars.palette.background.paper,
                            transform: "scale(1.05)",
                        },
                    }}
                >
                    <AddIcon />
                </IconButton>
                <IconButton
                    onClick={handleZoomOut}
                    sx={{
                        bgcolor: (theme) => theme.vars.palette.background.paper,
                        boxShadow: (theme) => theme.shadows[4],
                        width: 48,
                        height: 48,
                        borderRadius: "16px",
                        transition: "transform 0.2s ease-out",
                        "&:hover": {
                            bgcolor: (theme) =>
                                theme.vars.palette.background.paper,
                            transform: "scale(1.05)",
                        },
                    }}
                >
                    <RemoveIcon />
                </IconButton>
            </Stack>
        </>
    );
};

interface MapViewportListenerProps {
    useMap: typeof import("react-leaflet").useMap;
    photos: JourneyPoint[];
    onVisiblePhotosChange: (photosInView: JourneyPoint[]) => void;
}

const MapViewportListener: React.FC<MapViewportListenerProps> = ({
    useMap,
    photos,
    onVisiblePhotosChange,
}) => {
    const map = useMap();

    const updateVisiblePhotos = useCallback(() => {
        const bounds = map.getBounds();
        const inView = photos.filter((photo) =>
            bounds.contains([photo.lat, photo.lng]),
        );
        onVisiblePhotosChange(inView);
    }, [map, onVisiblePhotosChange, photos]);

    useEffect(() => {
        if (!photos.length) {
            onVisiblePhotosChange([]);
            return;
        }
        updateVisiblePhotos();
    }, [photos, onVisiblePhotosChange, updateVisiblePhotos]);

    useEffect(() => {
        map.on("moveend", updateVisiblePhotos);
        map.on("zoomend", updateVisiblePhotos);
        return () => {
            map.off("moveend", updateVisiblePhotos);
            map.off("zoomend", updateVisiblePhotos);
        };
    }, [map, updateVisiblePhotos]);

    return null;
};

export const CollectionMapDialog: React.FC<CollectionMapDialogProps> = ({
    open,
    onClose,
    collectionSummary,
    activeCollection,
}) => {
    const { onGenericError } = useBaseContext();

    const [mapComponents, setMapComponents] = useState<MapComponents | null>(
        null,
    ); // for storing the leaflet elements

    const [mapCenter, setMapCenter] = useState<[number, number] | null>(null); //stores the center fo the map for rendering

    const [filesByID, setFilesByID] = useState<Map<number, EnteFile>>(
        new Map(),
    ); //maintains a map for the files in view for the thumbnail population

    const [mapPhotos, setMapPhotos] = useState<JourneyPoint[]>([]); //flat list of all geotagged photos, powers the map markers
    const [thumbByFileID, setThumbByFileID] = useState<Map<number, string>>(
        new Map(),
    ); // map storing the file thumbnails against the fileID for showing the file thumbnails in the left sidebar
    const [visiblePhotos, setVisiblePhotos] = useState<JourneyPoint[]>([]);
    const [visiblePhotosWave, setVisiblePhotosWave] = useState(0);

    // FileViewer state
    const [openFileViewer, setOpenFileViewer] = useState(false);
    const [currentFileIndex, setCurrentFileIndex] = useState(0);
    const [viewerFiles, setViewerFiles] = useState<EnteFile[]>([]);

    const user = useMemo(() => {
        try {
            return ensureLocalUser();
        } catch {
            return undefined;
        }
    }, []);

    const formatDateLabel = (timestamp: string) =>
        new Date(timestamp).toLocaleDateString(undefined, {
            weekday: "long",
            day: "numeric",
            month: "short",
        });

    const photosByDate = useMemo(() => {
        const groups = new Map<string, JourneyPoint[]>();
        visiblePhotos.forEach((p) => {
            const dateLabel = formatDateLabel(p.timestamp);
            if (!groups.has(dateLabel)) {
                groups.set(dateLabel, []);
            }
            groups.get(dateLabel)!.push(p);
        });
        return Array.from(groups.entries());
    }, [visiblePhotos]);

    const visiblePhotoOrder = useMemo(() => {
        return new Map(visiblePhotos.map((p, index) => [p.fileId, index]));
    }, [visiblePhotos]);

    useEffect(() => {
        setVisiblePhotosWave((wave) => wave + 1);
    }, [visiblePhotos]);

    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const optimalZoom = calculateOptimalZoom();

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

    useEffect(() => {
        if (!open) return;
        void loadMapData();
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [open, collectionSummary.id, activeCollection.id]);

    const loadAllThumbs = async (points: JourneyPoint[], files: EnteFile[]) => {
        const sortedPoints = [...points].sort(
            (a, b) =>
                new Date(b.timestamp).getTime() -
                new Date(a.timestamp).getTime(),
        );

        const entries = await Promise.all(
            sortedPoints.map(async (p) => {
                if (p.image) return [p.fileId, p.image] as const;
                const file =
                    filesByID.get(p.fileId) ??
                    files.find((f) => f.id === p.fileId);
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

        setThumbByFileID(
            new Map(
                entries.filter(([, t]) => t !== undefined) as [
                    number,
                    string,
                ][],
            ),
        );
    };

    const loadMapData = async () => {
        setIsLoading(true);
        setError(null);
        try {
            const files = await filesForCollection();

            const locationPoints: JourneyPoint[] = [];
            files.forEach((file) => {
                const loc = fileLocation(file);
                if (!loc) return;
                locationPoints.push({
                    lat: loc.latitude,
                    lng: loc.longitude,
                    name: fileFileName(file),
                    country: "",
                    timestamp: new Date(
                        fileCreationTime(file) / 1000,
                    ).toISOString(),
                    image: "",
                    fileId: file.id,
                });
            });

            if (!locationPoints.length) {
                setMapCenter(null);
                setFilesByID(new Map());
                setMapPhotos([]);
                return;
            }

            locationPoints.sort(
                (a, b) =>
                    new Date(b.timestamp).getTime() -
                    new Date(a.timestamp).getTime(),
            );

            // Generate thumbnails for all photos
            const { thumbnailUpdates } = await generateNeededThumbnails({
                photoClusters: [locationPoints], // Wrap in array for compatibility
                files,
            });

            const pointsWithThumbs = locationPoints.map((point) => {
                const thumb = thumbnailUpdates.get(point.fileId);
                return thumb ? { ...point, image: thumb } : point;
            });

            setFilesByID(new Map(files.map((file) => [file.id, file])));
            setMapCenter(getMapCenter([], pointsWithThumbs));
            setMapPhotos(pointsWithThumbs);
            void loadAllThumbs(pointsWithThumbs, files);
        } catch (e) {
            setError(t("something_went_wrong"));
            onGenericError(e);
        } finally {
            setIsLoading(false);
        }
    };

    const filesForCollection = async () => {
        const allFiles = await savedCollectionFiles();
        const filtered =
            collectionSummary.type === "hiddenItems"
                ? await filesForHiddenItems(allFiles)
                : allFiles.filter(
                      (file) => file.collectionID === activeCollection.id,
                  );

        return uniqueFilesByID(filtered);
    };

    const filesForHiddenItems = async (files: EnteFile[]) => {
        const hiddenCollections = findDefaultHiddenCollectionIDs(
            await savedCollections(),
        );
        return files.filter((file) => hiddenCollections.has(file.collectionID));
    };

    // Map to store position -> photo data for cluster icon access
    const photosByPosition = useMemo(() => {
        const map = new Map<string, JourneyPoint>();
        mapPhotos.forEach((photo) => {
            const key = `${photo.lat},${photo.lng}`;
            map.set(key, photo);
        });
        return map;
    }, [mapPhotos]);

    // Custom cluster icon creator function for react-leaflet-cluster
    const createClusterCustomIcon = useCallback(
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        (cluster: any) => {
            // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-call
            const count = cluster.getChildCount();
            // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-call
            const childMarkers = cluster.getAllChildMarkers();

            // Get the first marker with an image as the cluster thumbnail
            let thumbnailUrl = "";
            for (const marker of childMarkers) {
                // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-call
                const latlng = marker.getLatLng();
                // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
                const key = `${latlng.lat},${latlng.lng}`;
                const photo = photosByPosition.get(key);
                if (photo) {
                    // Use thumbByFileID first, fallback to photo.image
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

    // Handle thumbnail click to open FileViewer
    const handlePhotoClick = useCallback(
        (fileId: number) => {
            // Get all files from filesByID sorted by creation time
            const allFiles = Array.from(filesByID.values()).sort(
                (a, b) =>
                    new Date(fileCreationTime(b) / 1000).getTime() -
                    new Date(fileCreationTime(a) / 1000).getTime(),
            );

            // Find the index of the clicked file
            const clickedIndex = allFiles.findIndex((f) => f.id === fileId);

            if (clickedIndex !== -1 && allFiles.length > 0) {
                setViewerFiles(allFiles);
                setCurrentFileIndex(clickedIndex);
                setOpenFileViewer(true);
            }
        },
        [filesByID],
    );

    const handleCloseFileViewer = useCallback(() => {
        setOpenFileViewer(false);
    }, []);

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

        const { MapContainer, TileLayer, Marker, useMap, MarkerClusterGroup } =
            mapComponents;
        return (
            <Box sx={{ display: "flex", height: "100%", width: "100%" }}>
                {/* Left sidebar */}
                <Box
                    sx={{
                        width: "600px",
                        height: "100%",
                        bgcolor: (theme) => theme.vars.palette.background.paper,
                        boxShadow: (theme) => theme.shadows[6],
                        display: "flex",
                        flexDirection: "column",
                        overflowY: "auto",
                        padding: 2,
                    }}
                >
                    {/* Sticky header section */}
                    <Box
                        sx={{
                            position: "sticky",
                            top: -16, // Stick to the very top
                            mx: -2, // Extend to edges
                            px: 2, // Add padding back
                            pt: 2, // Add padding for content spacing
                            bgcolor: (theme) =>
                                theme.vars.palette.background.paper,
                            zIndex: 3,
                            pb: 2,
                        }}
                    >
                        <Box
                            sx={{
                                display: "flex",
                                justifyContent: "space-between",
                                alignItems: "center",
                                gap: 1,
                            }}
                        >
                            <Stack>
                                <Typography
                                    variant="h5"
                                    sx={{ fontWeight: 700 }}
                                    noWrap
                                >
                                    {collectionSummary.name}
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
                                    {visiblePhotos.length}{" "}
                                    {t("memories", {
                                        defaultValue: "memories",
                                    })}
                                    {collectionSummary.fileCount !==
                                        mapPhotos.length && (
                                        <Tooltip
                                            title={`${collectionSummary.fileCount - mapPhotos.length} images aren't shown since they don't have the proper location metadata`}
                                            arrow
                                        >
                                            <InfoOutlinedIcon
                                                sx={{
                                                    fontSize: 16,
                                                    color: "text.muted",
                                                    cursor: "pointer",
                                                }}
                                            />
                                        </Tooltip>
                                    )}
                                </Typography>
                            </Stack>
                        </Box>
                    </Box>
                    {/* Scrollable photo content */}
                    <Stack spacing={1.5}>
                        {visiblePhotos.length ? (
                            photosByDate.map(([dateLabel, photos]) => (
                                <Stack key={dateLabel} spacing={0.75}>
                                    <Box
                                        sx={{
                                            position: "sticky",
                                            top: 56,
                                            bgcolor: (theme) =>
                                                theme.vars.palette.background
                                                    .paper,
                                            zIndex: 2,
                                            py: 1.5,
                                            ml: -2,
                                            mr: -2,
                                            pr: 2,
                                        }}
                                    >
                                        <Typography
                                            variant="small"
                                            color="text.secondary"
                                        >
                                            {dateLabel}
                                        </Typography>
                                    </Box>
                                    <ThumbRow>
                                        {photos.map((p, idx) => {
                                            const thumb = thumbByFileID.get(
                                                p.fileId,
                                            );
                                            const photoOrderIndex =
                                                visiblePhotoOrder.get(
                                                    p.fileId,
                                                ) ?? idx;
                                            const animationDelay =
                                                photoOrderIndex * 30;
                                            if (!thumb) {
                                                return (
                                                    <PlaceholderThumb
                                                        key={`${p.fileId}-${visiblePhotosWave}`}
                                                        animationDelay={
                                                            animationDelay
                                                        }
                                                    />
                                                );
                                            }
                                            return (
                                                <ThumbImage
                                                    key={`${p.fileId}-${visiblePhotosWave}`}
                                                    src={thumb}
                                                    alt={t("view_on_map")}
                                                    onClick={() =>
                                                        handlePhotoClick(
                                                            p.fileId,
                                                        )
                                                    }
                                                    animationDelay={
                                                        animationDelay
                                                    }
                                                />
                                            );
                                        })}
                                    </ThumbRow>
                                </Stack>
                            ))
                        ) : (
                            <NoVisiblePhotos>
                                <Typography
                                    variant="body"
                                    sx={{ fontWeight: 600 }}
                                >
                                    {t("no_photos_found_here", {
                                        defaultValue: "No photos found here",
                                    })}
                                </Typography>
                                <Typography
                                    variant="small"
                                    color="text.secondary"
                                >
                                    {t("zoom_out_to_see_photos", {
                                        defaultValue: "Zoom out to see photos",
                                    })}
                                </Typography>
                            </NoVisiblePhotos>
                        )}
                    </Stack>
                </Box>
                {/* Map container on the right */}
                <Box sx={{ flex: 1, position: "relative" }}>
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
                        <MapControls useMap={useMap} onClose={onClose} />
                        <MapViewportListener
                            useMap={useMap}
                            photos={mapPhotos}
                            onVisiblePhotosChange={setVisiblePhotos}
                        />
                        <MarkerClusterGroup
                            chunkedLoading
                            iconCreateFunction={createClusterCustomIcon}
                            maxClusterRadius={80}
                            spiderfyOnMaxZoom={true}
                            showCoverageOnHover={false}
                            zoomToBoundsOnClick={true}
                            animate={true}
                            animateAddingMarkers={true}
                            spiderfyDistanceMultiplier={1.5}
                        >
                            {mapPhotos.map((photo) => {
                                const thumbnailUrl =
                                    thumbByFileID.get(photo.fileId) ??
                                    photo.image;
                                const icon = createIcon(
                                    thumbnailUrl,
                                    68,
                                    "#f6f6f6",
                                    undefined,
                                    false,
                                );
                                return (
                                    <Marker
                                        key={photo.fileId}
                                        position={[photo.lat, photo.lng]}
                                        icon={icon ?? undefined}
                                    />
                                );
                            })}
                        </MarkerClusterGroup>
                    </MapContainer>
                </Box>
            </Box>
        );
    }, [
        createClusterCustomIcon,
        error,
        isLoading,
        mapCenter,
        mapComponents,
        optimalZoom,
        mapPhotos,
        thumbByFileID,
        photosByDate,
        collectionSummary.name,
        collectionSummary.fileCount,
        onClose,
        handlePhotoClick,
        visiblePhotoOrder,
        visiblePhotos.length,
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
                onVisualFeedback={() => {
                    // No-op for map view
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

interface CenteredBoxProps extends React.PropsWithChildren {
    onClose?: () => void;
    closeLabel?: string;
}

const CenteredBox: React.FC<CenteredBoxProps> = ({
    children,
    onClose,
    closeLabel,
}) => (
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
        {onClose ? (
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
        ) : null}
        {children}
    </Box>
);

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

const ThumbRow: React.FC<React.PropsWithChildren> = ({ children }) => (
    <Box
        sx={{
            display: "flex",
            flexWrap: "wrap",
            gap: 0.25,
            pb: 1,
            overflow: "hidden",
        }}
    >
        {children}
    </Box>
);

const NoVisiblePhotos: React.FC<React.PropsWithChildren> = ({ children }) => (
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

const ThumbImage = ({
    src,
    alt,
    onClick,
    animationDelay,
}: {
    src: string;
    alt: string;
    onClick?: () => void;
    animationDelay: number;
}) => (
    <Box
        component="img"
        src={src}
        alt={alt}
        onClick={onClick}
        sx={{
            width: 140,
            height: 140,
            objectFit: "cover",
            borderRadius: 0,
            flexShrink: 0,
            border: (theme) => `1px solid ${theme.palette.divider}`,
            cursor: onClick ? "pointer" : "default",
            transition: "transform 0.15s ease-in-out",
            opacity: 0,
            transformOrigin: "top left",
            animation: `${cascadeFadeIn} 200ms ease-out forwards`,
            animationDelay: `${animationDelay}ms`,
            "&:hover": onClick ? { transform: "scale(1.02)" } : {},
        }}
    />
);

const PlaceholderThumb = ({ animationDelay }: { animationDelay: number }) => (
    <Box
        sx={{
            width: 140,
            height: 140,
            borderRadius: 0,
            flexShrink: 0,
            bgcolor: (theme) => theme.vars.palette.fill.faint,
            border: (theme) => `1px solid ${theme.palette.divider}`,
            opacity: 0,
            transformOrigin: "top left",
            animation: `${cascadeFadeIn} 200ms ease-out forwards`,
            animationDelay: `${animationDelay}ms`,
        }}
    />
);
