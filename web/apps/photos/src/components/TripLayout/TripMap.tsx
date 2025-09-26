import { Box, styled } from "@mui/material";
import { useIsTouchscreen } from "ente-base/components/utils/hooks";
import dynamic from "next/dynamic";

import { MapEvents } from "./MapEvents";
import {
    createIcon,
    createSuperClusterIcon,
    detectScreenCollisions,
    getMapCenter,
} from "./mapHelpers";
import type { JourneyPoint } from "./types";

// Dynamically import react-leaflet components to prevent SSR issues
const MapContainer = dynamic(
    () => import("react-leaflet").then((mod) => mod.MapContainer),
    { ssr: false },
);
const TileLayer = dynamic(
    () => import("react-leaflet").then((mod) => mod.TileLayer),
    { ssr: false },
);
const Marker = dynamic(
    () => import("react-leaflet").then((mod) => mod.Marker),
    { ssr: false },
);

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
    const isTouchDevice = useIsTouchscreen();

    // Calculate current active location index based on scroll progress (same logic as in scrollUtils)
    let currentActiveLocationIndex = -1;
    if (photoClusters.length > 0) {
        if (isTouchDevice) {
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

    // Calculate super-clusters based on screen collisions, excluding the active cluster
    const { superClusters, visibleClustersWithIndices } =
        detectScreenCollisions(
            photoClusters,
            currentZoom,
            targetZoom,
            mapRef,
            optimalZoom,
            currentActiveLocationIndex >= 0
                ? currentActiveLocationIndex
                : undefined,
        );

    return (
        <MapContainerWrapper hasPhotoData={hasPhotoData}>
            {hasPhotoData ? (
                <StyledMapContainer
                    center={getMapCenter(
                        photoClusters,
                        journeyData,
                        superClusterInfo,
                    )}
                    zoom={
                        isTouchDevice
                            ? Math.max(1, optimalZoom - 2)
                            : optimalZoom
                    }
                    scrollWheelZoom={true}
                    zoomControl={false}
                    attributionControl={!isTouchDevice}
                >
                    <MapEvents
                        setMapRef={setMapRef}
                        setCurrentZoom={setCurrentZoom}
                        setTargetZoom={setTargetZoom}
                    />
                    {/* Stadia Alidade Satellite - includes both imagery and labels */}
                    <TileLayer
                        attribution={
                            isTouchDevice
                                ? ""
                                : '&copy; <a href="https://stadiamaps.com/">Stadia Maps</a>, &copy; <a href="https://openmaptiles.org/">OpenMapTiles</a> &copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors'
                        }
                        url="https://tiles.stadiamaps.com/tiles/alidade_satellite/{z}/{x}/{y}{r}.jpg"
                        maxZoom={20}
                        updateWhenZooming={false}
                        keepBuffer={1}
                    />

                    {/* Draw super-clusters (clickable for zoom and gallery) */}
                    {superClusters.map((superCluster, index) => {
                        // Show green only for active locations
                        let currentLocationIndex;
                        if (isTouchDevice) {
                            // Mobile: Slower progression - stay on each location longer
                            currentLocationIndex = Math.floor(
                                scrollProgress * (photoClusters.length - 0.5),
                            );
                        } else {
                            // Desktop: Use original logic
                            currentLocationIndex = Math.round(
                                scrollProgress *
                                    Math.max(0, photoClusters.length - 1),
                            );
                        }
                        const isActive =
                            superCluster.clustersInvolved.includes(
                                currentLocationIndex,
                            );

                        const icon = createSuperClusterIcon(
                            superCluster.image, // Use representative photo (first photo of first cluster)
                            superCluster.clusterCount,
                            isTouchDevice ? 40 : 55,
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
                                            onMarkerClick(
                                                firstClusterIndex,
                                                superCluster.lat,
                                                superCluster.lng,
                                            );
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
                        let currentLocationIndex;
                        if (isTouchDevice) {
                            // Mobile: Slower progression - stay on each location longer
                            currentLocationIndex = Math.floor(
                                scrollProgress * (photoClusters.length - 0.5),
                            );
                        } else {
                            // Desktop: Use original logic
                            currentLocationIndex = Math.round(
                                scrollProgress *
                                    Math.max(0, photoClusters.length - 1),
                            );
                        }
                        const isActive =
                            originalClusterIndex === currentLocationIndex;

                        const icon = createIcon(
                            firstPhoto.image,
                            isTouchDevice ? 40 : 55,
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
                </StyledMapContainer>
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

const StyledMapContainer = styled(MapContainer)({
    width: "100%",
    height: "100%",
});
