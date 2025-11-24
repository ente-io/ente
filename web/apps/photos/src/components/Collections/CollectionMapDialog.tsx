import CloseIcon from "@mui/icons-material/Close";
import KeyboardArrowDownIcon from "@mui/icons-material/KeyboardArrowDown";
import KeyboardArrowUpIcon from "@mui/icons-material/KeyboardArrowUp";
import {
    Box,
    Dialog,
    DialogContent,
    IconButton,
    Stack,
    Typography,
} from "@mui/material";
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
} from "ente-media/file-metadata";
import { findDefaultHiddenCollectionIDs } from "ente-new/photos/services/collection";
import { type CollectionSummary } from "ente-new/photos/services/collection-summary";
import {
    savedCollectionFiles,
    savedCollections,
} from "ente-new/photos/services/photos-fdb";
import { t } from "i18next";
import "leaflet/dist/leaflet.css";
import React, { useEffect, useMemo, useState } from "react";
import {
    calculateOptimalZoom,
    clusterPhotosByProximity,
    createIcon,
    getMapCenter,
} from "../TripLayout/mapHelpers";
import type { JourneyPoint } from "../TripLayout/types";
import { generateNeededThumbnails } from "../TripLayout/utils/dataProcessing";

interface MapComponents {
    MapContainer: typeof import("react-leaflet").MapContainer;
    TileLayer: typeof import("react-leaflet").TileLayer;
    Marker: typeof import("react-leaflet").Marker;
}

interface CollectionMapDialogProps extends ModalVisibilityProps {
    collectionSummary: CollectionSummary;
    activeCollection: Collection;
}

interface MapClusterMeta {
    lat: number;
    lng: number;
    count: number;
    thumbnail?: string;
    fileIDs: number[];
}

export const CollectionMapDialog: React.FC<CollectionMapDialogProps> = ({
    open,
    onClose,
    collectionSummary,
    activeCollection,
}) => {
    const { onGenericError } = useBaseContext();

    const [mapComponents, setMapComponents] = useState<MapComponents | null>(
        null,
    );
    const [photoClusters, setPhotoClusters] = useState<JourneyPoint[][]>([]);
    const [mapCenter, setMapCenter] = useState<[number, number] | null>(null);
    const [selectedClusterIndex, setSelectedClusterIndex] = useState(0);
    const [filesByID, setFilesByID] = useState<Map<number, EnteFile>>(
        new Map(),
    );
    const [mapPhotos, setMapPhotos] = useState<JourneyPoint[]>([]);
    const [thumbByFileID, setThumbByFileID] = useState<Map<number, string>>(
        new Map(),
    );
    const [expanded, setExpanded] = useState(false);
    const formatDateLabel = (timestamp: string) =>
        new Date(timestamp).toLocaleDateString(undefined, {
            weekday: "long",
            day: "numeric",
            month: "short",
        });

    const photosByDate = useMemo(() => {
        const groups = new Map<string, JourneyPoint[]>();
        mapPhotos.forEach((p) => {
            const dateLabel = formatDateLabel(p.timestamp);
            if (!groups.has(dateLabel)) {
                groups.set(dateLabel, []);
            }
            groups.get(dateLabel)!.push(p);
        });
        return Array.from(groups.entries());
    }, [mapPhotos]);

    const visiblePhotosByDate = useMemo(
        () => (expanded ? photosByDate : photosByDate.slice(0, 2)),
        [expanded, photosByDate],
    );
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const optimalZoom = calculateOptimalZoom();

    useEffect(() => {
        void import("react-leaflet")
            .then((mod) =>
                setMapComponents({
                    MapContainer: mod.MapContainer,
                    TileLayer: mod.TileLayer,
                    Marker: mod.Marker,
                }),
            )
            .catch((e: unknown) => {
                console.error("Failed to load map components", e);
            });
    }, []);

    useEffect(() => {
        if (!open) return;
        setSelectedClusterIndex(0);
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
                setPhotoClusters([]);
                setMapCenter(null);
                setFilesByID(new Map());
                return;
            }

            locationPoints.sort(
                (a, b) =>
                    new Date(b.timestamp).getTime() -
                    new Date(a.timestamp).getTime(),
            );

            const clusters = clusterPhotosByProximity(locationPoints);
            const { thumbnailUpdates } = await generateNeededThumbnails({
                photoClusters: clusters,
                files,
            });

            const pointsWithThumbs = locationPoints.map((point) => {
                const thumb = thumbnailUpdates.get(point.fileId);
                return thumb ? { ...point, image: thumb } : point;
            });
            const clustersWithThumbs =
                clusterPhotosByProximity(pointsWithThumbs);

            setPhotoClusters(clustersWithThumbs);
            setFilesByID(new Map(files.map((file) => [file.id, file])));
            setMapCenter(getMapCenter(clustersWithThumbs, pointsWithThumbs));
            setMapPhotos(pointsWithThumbs);
            void loadAllThumbs(pointsWithThumbs, files);
            setSelectedClusterIndex(0);
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

    const clusterMeta = useMemo<MapClusterMeta[]>(() => {
        return photoClusters.map((cluster) => {
            const avgLat =
                cluster.reduce((sum, p) => sum + p.lat, 0) / cluster.length;
            const avgLng =
                cluster.reduce((sum, p) => sum + p.lng, 0) / cluster.length;
            const preview = cluster.find((p) => p.image)?.image;
            return {
                lat: avgLat,
                lng: avgLng,
                count: cluster.length,
                thumbnail: preview,
                fileIDs: cluster.map((p) => p.fileId),
            };
        });
    }, [photoClusters]);

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
        if (!photoClusters.length || !mapCenter) {
            return (
                <CenteredBox>
                    <Typography variant="body" color="text.secondary">
                        {t("view_on_map")}
                    </Typography>
                    <Typography variant="small" color="text.secondary">
                        {t("maps_privacy_notice")}
                    </Typography>
                </CenteredBox>
            );
        }

        const { MapContainer, TileLayer, Marker } = mapComponents;
        return (
            <Box sx={{ position: "relative", height: "100%", width: "100%" }}>
                <MapContainer
                    center={mapCenter}
                    zoom={optimalZoom}
                    scrollWheelZoom
                    style={{ width: "100%", height: "100%" }}
                >
                    <TileLayer
                        attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
                        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                        maxZoom={19}
                        updateWhenZooming
                    />
                    {clusterMeta.map((cluster, index) => {
                        const icon = createIcon(
                            cluster.thumbnail ?? "",
                            index === selectedClusterIndex ? 55 : 45,
                            "#ffffff",
                            cluster.count,
                            index === selectedClusterIndex,
                        );
                        return (
                            <Marker
                                key={`${cluster.lat}-${cluster.lng}-${index}`}
                                position={[cluster.lat, cluster.lng]}
                                icon={icon ?? undefined}
                                eventHandlers={{
                                    click: () => setSelectedClusterIndex(index),
                                }}
                            />
                        );
                    })}
                </MapContainer>
                <BottomPanel expanded={expanded}>
                    <Stack spacing={1}>
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
                                    sx={{ mt: 0.25, mb: 1 }}
                                >
                                    {mapPhotos.length}{" "}
                                    {t("memories", {
                                        defaultValue: "memories",
                                    })}
                                </Typography>
                            </Stack>
                            <Stack direction="row" spacing={1}>
                                <IconButton
                                    onClick={() => setExpanded((prev) => !prev)}
                                    aria-label={
                                        expanded ? t("collapse") : t("expand")
                                    }
                                    sx={{
                                        bgcolor: (theme) =>
                                            theme.vars.palette.background.paper,
                                        boxShadow: (theme) => theme.shadows[2],
                                    }}
                                >
                                    {expanded ? (
                                        <KeyboardArrowDownIcon />
                                    ) : (
                                        <KeyboardArrowUpIcon />
                                    )}
                                </IconButton>
                                <IconButton
                                    onClick={onClose}
                                    aria-label={t("close")}
                                    sx={{
                                        bgcolor: (theme) =>
                                            theme.vars.palette.background.paper,
                                        boxShadow: (theme) => theme.shadows[2],
                                    }}
                                >
                                    <CloseIcon />
                                </IconButton>
                            </Stack>
                        </Box>
                        <Stack spacing={1.5}>
                            {visiblePhotosByDate.map(([dateLabel, photos]) => (
                                <Stack key={dateLabel} spacing={0.75}>
                                    <Typography
                                        variant="small"
                                        color="text.secondary"
                                        sx={{ mb: 0.25 }}
                                    >
                                        {dateLabel}
                                    </Typography>
                                    <ThumbRow>
                                        {photos.map((p, idx) => {
                                            const thumb = thumbByFileID.get(
                                                p.fileId,
                                            );
                                            if (!thumb) {
                                                return (
                                                    <PlaceholderThumb
                                                        key={p.fileId}
                                                    />
                                                );
                                            }
                                            return (
                                                <ThumbImage
                                                    key={`${thumb}-${idx}`}
                                                    src={thumb}
                                                    alt={t("view_on_map")}
                                                />
                                            );
                                        })}
                                    </ThumbRow>
                                </Stack>
                            ))}
                        </Stack>
                    </Stack>
                </BottomPanel>
            </Box>
        );
    }, [
        clusterMeta,
        error,
        isLoading,
        mapCenter,
        mapComponents,
        optimalZoom,
        mapPhotos.length,
        mapPhotos,
        thumbByFileID,
        photosByDate,
        expanded,
        visiblePhotosByDate,
    ]);

    return (
        <Dialog fullScreen open={open} onClose={onClose}>
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

const CenteredBox: React.FC<React.PropsWithChildren> = ({ children }) => (
    <Box
        sx={{
            width: "100%",
            height: "100%",
            minHeight: "420px",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            gap: 1,
            flexDirection: "column",
            textAlign: "center",
        }}
    >
        {children}
    </Box>
);

const BottomPanel: React.FC<React.PropsWithChildren<{ expanded: boolean }>> = ({
    expanded,
    children,
}) => (
    <Box
        sx={{
            position: "absolute",
            bottom: 0,
            left: 0,
            right: 0,
            zIndex: (theme) => theme.zIndex.modal,
            bgcolor: (theme) => theme.vars.palette.background.paper,
            boxShadow: (theme) => theme.shadows[6],
            p: 2,
            borderTopLeftRadius: 12,
            borderTopRightRadius: 12,
            maxHeight: expanded ? "75vh" : "45vh",
            overflowY: "auto",
        }}
    >
        {children}
    </Box>
);

const ThumbRow: React.FC<React.PropsWithChildren> = ({ children }) => (
    <Box sx={{ display: "flex", flexWrap: "wrap", gap: 0.25, pb: 1 }}>
        {children}
    </Box>
);

const ThumbImage = ({ src, alt }: { src: string; alt: string }) => (
    <Box
        component="img"
        src={src}
        alt={alt}
        sx={{
            width: 100,
            height: 100,
            objectFit: "cover",
            borderRadius: 0,
            flexShrink: 0,
            border: (theme) => `1px solid ${theme.palette.divider}`,
        }}
    />
);

const PlaceholderThumb = () => (
    <Box
        sx={{
            width: 100,
            height: 100,
            borderRadius: 0,
            flexShrink: 0,
            bgcolor: (theme) => theme.vars.palette.fill.faint,
            border: (theme) => `1px solid ${theme.palette.divider}`,
        }}
    />
);
