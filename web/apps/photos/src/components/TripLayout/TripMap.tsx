import { Box, styled, useMediaQuery, useTheme } from "@mui/material";
import { useEffect, useState } from "react";

import { MapEvents } from "./MapEvents";
import {
    createIcon,
    createSuperClusterIcon,
    detectScreenCollisions,
    getMapCenter,
} from "./mapHelpers";
import type { JourneyPoint } from "./types";

interface MapComponentsType {
    MapContainer: typeof import("react-leaflet").MapContainer;
    TileLayer: typeof import("react-leaflet").TileLayer;
    Marker: typeof import("react-leaflet").Marker;
}

interface TripMapProps {
    journeyData: JourneyPoint[];
    photoClusters: JourneyPoint[][];
    hasPhotoData: boolean;
    optimalZoom: number;
    currentZoom: number;
    targetZoom: number | null;
    mapRef: import("leaflet").Map | null;
    scrollProgress: number;
    superClusterInfo?: {
        superClusters: {
            lat: number;
            lng: number;
            clusterCount: number;
            clustersInvolved: number[];
            image: string;
        }[];
        clusterToSuperClusterMap: Map<number, number>;
    };
    setMapRef: (map: import("leaflet").Map | null) => void;
    setCurrentZoom: (zoom: number) => void;
    setTargetZoom: (zoom: number | null) => void;
    onMarkerClick: (
        clusterIndex: number,
        clusterLat: number,
        clusterLng: number,
    ) => void;
}

export const TripMap: React.FC<TripMapProps> = ({
    journeyData,
    photoClusters,
    hasPhotoData,
    optimalZoom,
    currentZoom,
    targetZoom,
    mapRef,
    scrollProgress,
    superClusterInfo,
    setMapRef,
    setCurrentZoom,
    setTargetZoom,
    onMarkerClick,
}) => {
    const theme = useTheme();
    const isMobileOrTablet = useMediaQuery(theme.breakpoints.down("md")); // 960px breakpoint for mobile and tablet

    // Load react-leaflet components client-side only to prevent SSR issues
    const [mapComponents, setMapComponents] =
        useState<MapComponentsType | null>(null);

    useEffect(() => {
        void import("react-leaflet")
            .then((mod) => {
                setMapComponents({
                    MapContainer: mod.MapContainer,
                    TileLayer: mod.TileLayer,
                    Marker: mod.Marker,
                });
            })
            .catch((error: unknown) => {
                console.error("Failed to load react-leaflet:", error);
            });
    }, []);

    // Calculate current active location index based on scroll progress (same logic as in scrollUtils)
    let currentActiveLocationIndex = -1;
    if (photoClusters.length > 0) {
        if (isMobileOrTablet) {
            // Mobile: Slower progression - stay on each location longer
            currentActiveLocationIndex = Math.floor(
                scrollProgress * (photoClusters.length - 0.5),
            );
        } else {
            // Desktop: Use original logic
            currentActiveLocationIndex = Math.round(
                scrollProgress * Math.max(0, photoClusters.length - 1),
            );
        }
    }

    // Calculate super-clusters based on screen collisions
    const { superClusters, visibleClustersWithIndices } =
        detectScreenCollisions(
            photoClusters,
            currentZoom,
            targetZoom,
            mapRef,
            optimalZoom,
        );

    // Return loading state if map components haven't loaded yet
    if (!mapComponents) {
        return <MapContainerWrapper hasPhotoData={false} />;
    }

    const { MapContainer, TileLayer, Marker } = mapComponents;

    return (
        <MapContainerWrapper hasPhotoData={hasPhotoData}>
            {hasPhotoData ? (
                <MapContainer
                    center={getMapCenter(
                        photoClusters,
                        journeyData,
                        superClusterInfo,
                    )}
                    zoom={
                        isMobileOrTablet
                            ? Math.max(1, optimalZoom - 2)
                            : optimalZoom
                    }
                    scrollWheelZoom={true}
                    zoomControl={false}
                    attributionControl={!isMobileOrTablet}
                    style={{ width: "100%", height: "100%" }}
                >
                    <MapEvents
                        setMapRef={setMapRef}
                        setCurrentZoom={setCurrentZoom}
                        setTargetZoom={setTargetZoom}
                    />
                    {/* Stadia Alidade Satellite - includes both imagery and labels */}
                    <TileLayer
                        attribution={
                            isMobileOrTablet
                                ? ""
                                : '&copy; <a href="https://stadiamaps.com/">Stadia Maps</a>, &copy; <a href="https://openmaptiles.org/">OpenMapTiles</a> &copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors'
                        }
                        url="https://tiles.stadiamaps.com/tiles/alidade_satellite/{z}/{x}/{y}{r}.jpg"
                        maxZoom={20}
                        updateWhenZooming={true}
                        keepBuffer={isMobileOrTablet ? 3 : 1}
                    />

                    {/* Draw super-clusters (clickable for zoom and gallery) */}
                    {superClusters.map((superCluster, index) => {
                        // Show green only for active locations
                        const isActive = superCluster.clustersInvolved.includes(
                            currentActiveLocationIndex,
                        );

                        const icon = createSuperClusterIcon(
                            superCluster.image, // Use representative photo (first photo of first cluster)
                            superCluster.clusterCount,
                            isMobileOrTablet ? 40 : 55,
                            isActive,
                        );

                        return icon ? (
                            <Marker
                                key={`super-cluster-${index}`}
                                position={[superCluster.lat, superCluster.lng]}
                                icon={icon}
                                eventHandlers={{
                                    click: () => {
                                        const firstClusterIndex =
                                            superCluster.clustersInvolved[0];
                                        if (firstClusterIndex !== undefined) {
                                            // Get the actual first cluster's coordinates
                                            const firstCluster =
                                                photoClusters[
                                                    firstClusterIndex
                                                ];
                                            if (firstCluster) {
                                                const avgLat =
                                                    firstCluster.reduce(
                                                        (sum, p) => sum + p.lat,
                                                        0,
                                                    ) / firstCluster.length;
                                                const avgLng =
                                                    firstCluster.reduce(
                                                        (sum, p) => sum + p.lng,
                                                        0,
                                                    ) / firstCluster.length;
                                                onMarkerClick(
                                                    firstClusterIndex,
                                                    avgLat,
                                                    avgLng,
                                                );
                                            }
                                        }
                                    },
                                }}
                            />
                        ) : null;
                    })}

                    {/* Draw visible regular clusters */}
                    {visibleClustersWithIndices.map((item, index) => {
                        const { cluster, originalIndex } = item;
                        const firstPhoto = cluster[0];
                        if (!firstPhoto) return null;
                        const avgLat =
                            cluster.reduce((sum, p) => sum + p.lat, 0) /
                            cluster.length;
                        const avgLng =
                            cluster.reduce((sum, p) => sum + p.lng, 0) /
                            cluster.length;

                        // Use the preserved original index
                        const originalClusterIndex = originalIndex;
                        // Show green only for active locations
                        const isActive =
                            originalClusterIndex === currentActiveLocationIndex;

                        const icon = createIcon(
                            firstPhoto.image,
                            isMobileOrTablet ? 40 : 55,
                            "#ffffff",
                            cluster.length,
                            isActive,
                        );

                        return icon ? (
                            <Marker
                                key={`cluster-${index}`}
                                position={[avgLat, avgLng]}
                                icon={icon}
                                eventHandlers={{
                                    click: () => {
                                        // Calculate cluster center
                                        const avgLat =
                                            cluster.reduce(
                                                (sum, p) => sum + p.lat,
                                                0,
                                            ) / cluster.length;
                                        const avgLng =
                                            cluster.reduce(
                                                (sum, p) => sum + p.lng,
                                                0,
                                            ) / cluster.length;
                                        onMarkerClick(
                                            originalClusterIndex,
                                            avgLat,
                                            avgLng,
                                        );
                                    },
                                }}
                            />
                        ) : null;
                    })}
                </MapContainer>
            ) : null}
        </MapContainerWrapper>
    );
};

// Styled components
const MapContainerWrapper = styled(Box, {
    shouldForwardProp: (prop) => prop !== "hasPhotoData",
})<{ hasPhotoData: boolean }>(({ hasPhotoData }) => ({
    width: "100%",
    height: "100%",
    backgroundColor: hasPhotoData ? "transparent" : "#000000",
}));
