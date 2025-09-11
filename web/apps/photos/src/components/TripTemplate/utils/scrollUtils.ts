import L from "leaflet";
import { startTransition } from "react";

import type { JourneyPoint } from "../types";

export interface PositionInfo {
    top: number;
    center: number;
}

export interface UpdateLocationPositionsParams {
    locationRefs: (HTMLDivElement | null)[];
    setLocationPositions: (positions: PositionInfo[]) => void;
}

export const updateLocationPositions = ({
    locationRefs,
    setLocationPositions,
}: UpdateLocationPositionsParams) => {
    if (locationRefs.length === 0) return;

    const positions = locationRefs.map((ref) => {
        if (!ref) return { top: 0, center: 0 };
        const rect = ref.getBoundingClientRect();
        const top = ref.offsetTop;
        const center = top + rect.height / 2;
        return { top, center };
    });

    startTransition(() => {
        setLocationPositions(positions);
    });
};

export interface HandleTimelineScrollParams {
    timelineRef: React.RefObject<HTMLDivElement | null>;
    photoClusters: JourneyPoint[][];
    locationPositions: PositionInfo[];
    mapRef: L.Map | null;
    screenDimensions: { width: number; height: number };
    optimalZoom: number;
    isClusterClickScrollingRef: React.MutableRefObject<boolean>;
    setHasUserScrolled: (scrolled: boolean) => void;
    setScrollProgress: (progress: number) => void;
}

export const handleTimelineScroll = ({
    timelineRef,
    photoClusters,
    locationPositions,
    mapRef,
    screenDimensions,
    optimalZoom,
    isClusterClickScrollingRef,
    setHasUserScrolled,
    setScrollProgress,
}: HandleTimelineScrollParams) => {
    if (
        !timelineRef.current ||
        photoClusters.length === 0 ||
        locationPositions.length === 0
    )
        return;

    const timelineContainer = timelineRef.current;
    const scrollHeight = timelineContainer.scrollHeight;
    const clientHeight = timelineContainer.clientHeight;
    const scrollTop = timelineContainer.scrollTop;

    const isAtBottom = scrollTop + clientHeight >= scrollHeight - 10;
    let progress = 0;
    if (isAtBottom) {
        progress = 1;
    } else {
        const maxScrollableDistance = scrollHeight - clientHeight;
        if (maxScrollableDistance > 0) {
            progress = scrollTop / maxScrollableDistance;
        } else {
            progress = 0;
        }
    }
    const clampedProgress = Math.min(1, Math.max(0, progress));

    if (isClusterClickScrollingRef.current) {
        return;
    }

    setHasUserScrolled(true);
    startTransition(() => {
        setScrollProgress(clampedProgress);
    });

    if (mapRef && !isClusterClickScrollingRef.current) {
        const clusterCenters = photoClusters.map((cluster) => {
            const avgLat = cluster.reduce((sum, p) => sum + p.lat, 0) / cluster.length;
            const avgLng = cluster.reduce((sum, p) => sum + p.lng, 0) / cluster.length;
            return { lat: avgLat, lng: avgLng };
        });

        if (clusterCenters.length > 0) {
            let targetLat, targetLng;

            const firstCenter = clusterCenters[0];
            const lastCenter = clusterCenters[clusterCenters.length - 1];
            if (!firstCenter || !lastCenter) return;

            if (clampedProgress <= 0) {
                targetLat = firstCenter.lat;
                targetLng = firstCenter.lng;
            } else if (clampedProgress === 1) {
                targetLat = lastCenter.lat;
                targetLng = lastCenter.lng;
            } else {
                const clusterProgress = clampedProgress * (clusterCenters.length - 1);
                const currentClusterIndex = Math.floor(clusterProgress);
                const nextClusterIndex = Math.min(
                    currentClusterIndex + 1,
                    clusterCenters.length - 1,
                );
                const lerpFactor = clusterProgress - currentClusterIndex;

                const currentCluster = clusterCenters[currentClusterIndex];
                const nextCluster = clusterCenters[nextClusterIndex];

                if (!currentCluster || !nextCluster) {
                    targetLat = clusterCenters[0]?.lat || 0;
                    targetLng = clusterCenters[0]?.lng || 0;
                } else {
                    targetLat =
                        currentCluster.lat +
                        (nextCluster.lat - currentCluster.lat) * lerpFactor;
                    targetLng =
                        currentCluster.lng +
                        (nextCluster.lng - currentCluster.lng) * lerpFactor;
                }
            }

            const timelineSizeRatio = 0.5;

            const allLngs = clusterCenters.map((c) => c.lng);
            const minLng = Math.min(...allLngs);
            const maxLng = Math.max(...allLngs);
            const lngSpan = maxLng - minLng;
            const paddedSpan = Math.max(lngSpan * 1.4, 0.1);

            const mapSizeRatio = 1 - timelineSizeRatio;
            const screenWidthInDegrees = paddedSpan / mapSizeRatio;
            const shiftAmount = screenWidthInDegrees * (timelineSizeRatio / 2);

            const adjustedLng = targetLng - shiftAmount;

            const currentMapZoom = mapRef.getZoom();

            if (currentMapZoom !== optimalZoom) {
                mapRef.flyTo([targetLat, adjustedLng], optimalZoom, {
                    animate: true,
                    duration: 0.5,
                    easeLinearity: 0.5,
                });
            } else {
                mapRef.panTo([targetLat, adjustedLng], {
                    animate: true,
                    duration: 0.3,
                    easeLinearity: 0.8,
                });
            }
        }
    }
};

export interface ScrollTimelineToLocationParams {
    timelineRef: React.RefObject<HTMLDivElement | null>;
    locationIndex: number;
    photoClusters: JourneyPoint[][];
    locationPositions: PositionInfo[];
}

export const scrollTimelineToLocation = ({
    timelineRef,
    locationIndex,
    photoClusters,
    locationPositions,
}: ScrollTimelineToLocationParams) => {
    if (
        !timelineRef.current ||
        locationIndex < 0 ||
        locationIndex >= photoClusters.length ||
        locationPositions.length === 0
    )
        return;

    const timelineContainer = timelineRef.current;
    const scrollHeight = timelineContainer.scrollHeight;
    const clientHeight = timelineContainer.clientHeight;
    const maxScrollableDistance = scrollHeight - clientHeight;

    const targetProgress = locationIndex / Math.max(1, photoClusters.length - 1);
    const targetScrollTop = targetProgress * maxScrollableDistance;

    timelineContainer.scrollTo({
        top: Math.max(0, Math.min(targetScrollTop, maxScrollableDistance)),
        behavior: "smooth",
    });
};

export interface HandleMarkerClickParams {
    clusterIndex: number;
    clusterLat: number;
    clusterLng: number;
    photoClusters: JourneyPoint[][];
    screenDimensions: { width: number; height: number };
    mapRef: L.Map | null;
    optimalZoom: number;
    isClusterClickScrollingRef: React.MutableRefObject<boolean>;
    clusterClickTimeoutRef: React.MutableRefObject<NodeJS.Timeout | null>;
    setScrollProgress: (progress: number) => void;
    scrollTimelineToLocation: (locationIndex: number) => void;
}

export const handleMarkerClick = ({
    clusterIndex,
    clusterLat,
    clusterLng,
    photoClusters,
    screenDimensions,
    mapRef,
    optimalZoom,
    isClusterClickScrollingRef,
    clusterClickTimeoutRef,
    setScrollProgress,
    scrollTimelineToLocation,
}: HandleMarkerClickParams) => {
    const targetProgress = clusterIndex / Math.max(1, photoClusters.length - 1);

    if (clusterClickTimeoutRef.current) {
        clearTimeout(clusterClickTimeoutRef.current);
    }

    isClusterClickScrollingRef.current = true;
    setScrollProgress(targetProgress);

    const allClusterLngs = photoClusters.map(
        (cluster) => cluster.reduce((sum, p) => sum + p.lng, 0) / cluster.length,
    );
    const minLng = Math.min(...allClusterLngs);
    const maxLng = Math.max(...allClusterLngs);
    const lngSpan = maxLng - minLng;
    const paddedSpan = Math.max(lngSpan * 1.4, 0.1);

    const timelineSizeRatio = 0.5;
    const mapSizeRatio = 1 - timelineSizeRatio;
    const screenWidthInDegrees = paddedSpan / mapSizeRatio;
    const shiftAmount = screenWidthInDegrees * (timelineSizeRatio / 2);
    const offsetLng = clusterLng - shiftAmount;

    if (mapRef) {
        const currentZoom = mapRef.getZoom();
        if (currentZoom > optimalZoom) {
            mapRef.flyTo([clusterLat, offsetLng], optimalZoom, {
                animate: true,
                duration: 1.2,
                easeLinearity: 0.25,
            });
        } else {
            mapRef.panTo([clusterLat, offsetLng], {
                animate: true,
                duration: 1.0,
            });
        }
    }

    setTimeout(() => {
        scrollTimelineToLocation(clusterIndex);
    }, 50);

    clusterClickTimeoutRef.current = setTimeout(() => {
        isClusterClickScrollingRef.current = false;
        clusterClickTimeoutRef.current = null;
    }, 1500);
};