import { Box, styled } from "@mui/material";
import { useIsTouchscreen } from "ente-base/components/utils/hooks";
import L from "leaflet";
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
    mapRef: L.Map | null;
    scrollProgress: number;
    setMapRef: (map: L.Map | null) => void;
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
    setMapRef,
    setCurrentZoom,
    setTargetZoom,
    onMarkerClick,
}) => {
    const isTouchDevice = useIsTouchscreen();

    // Calculate super-clusters based on screen collisions
    const { superClusters, visibleClusters } = detectScreenCollisions(
        photoClusters,
        currentZoom,
        targetZoom,
        mapRef,
        optimalZoom,
    );

    return (
        <MapContainerWrapper hasPhotoData={hasPhotoData}>
            {hasPhotoData ? (
                <StyledMapContainer
                    center={getMapCenter(photoClusters, journeyData)}
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
                    />

                    {/* Draw super-clusters (clickable for zoom and gallery) */}
                    {superClusters.map((superCluster, index) => {
                        // Show green for all covered locations (up to current position)
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
                        const isCovered = superCluster.clustersInvolved.some(
                            (clusterIndex) =>
                                clusterIndex <= currentLocationIndex,
                        );

                        return (
                            <Marker
                                key={`super-cluster-${index}`}
                                position={[superCluster.lat, superCluster.lng]}
                                icon={createSuperClusterIcon(
                                    superCluster.image, // Use representative photo (first photo of first cluster)
                                    superCluster.clusterCount,
                                    isTouchDevice ? 40 : 55,
                                    isCovered,
                                )}
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
                        );
                    })}

                    {/* Draw visible regular clusters */}
                    {visibleClusters.map((cluster, index) => {
                        const firstPhoto = cluster[0];
                        if (!firstPhoto) return null;
                        const avgLat =
                            cluster.reduce((sum, p) => sum + p.lat, 0) /
                            cluster.length;
                        const avgLng =
                            cluster.reduce((sum, p) => sum + p.lng, 0) /
                            cluster.length;

                        // Find the original cluster index
                        const originalClusterIndex = photoClusters.findIndex(
                            (originalCluster) =>
                                originalCluster.length === cluster.length &&
                                originalCluster[0]?.image === cluster[0]?.image,
                        );
                        // Show green for all covered locations (up to current position)
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
                        const isCovered =
                            originalClusterIndex <= currentLocationIndex;

                        return (
                            <Marker
                                key={`cluster-${index}`}
                                position={[avgLat, avgLng]}
                                icon={createIcon(
                                    firstPhoto.image,
                                    isTouchDevice ? 40 : 55,
                                    "#ffffff",
                                    cluster.length,
                                    isCovered,
                                )}
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
                        );
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
