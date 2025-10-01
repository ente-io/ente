import { startTransition } from "react";

import {
    calculateDistance,
    getLocationPosition,
    getLocationPositionAtZoom,
} from "../mapHelpers";
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
    mapRef: import("leaflet").Map | null;
    isClusterClickScrollingRef: React.RefObject<boolean>;
    setHasUserScrolled: (scrolled: boolean) => void;
    setScrollProgress: (progress: number) => void;
    previousActiveLocationRef: React.RefObject<number>;
    isTouchDevice: boolean;
    setTargetZoom: (zoom: number | null) => void;
    previousSuperClusterStateRef: React.RefObject<{
        isInSuperCluster: boolean;
        superClusterIndex: number | null;
    }>;
    superClusterInfo: {
        superClusters: {
            lat: number;
            lng: number;
            clusterCount: number;
            clustersInvolved: number[];
            image: string;
        }[];
        clusterToSuperClusterMap: Map<number, number>;
    };
}

export const handleTimelineScroll = ({
    timelineRef,
    photoClusters,
    locationPositions,
    mapRef,
    isClusterClickScrollingRef,
    setHasUserScrolled,
    setScrollProgress,
    previousActiveLocationRef,
    isTouchDevice,
    setTargetZoom,
    previousSuperClusterStateRef,
    superClusterInfo,
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

    // Calculate scroll progress (0 to 1)
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

    // Calculate current active location index based on scroll progress
    let currentActiveLocationIndex = -1; // Start with no location selected
    if (photoClusters.length > 0) {
        if (isTouchDevice) {
            // Mobile: Slower progression - stay on each location longer
            currentActiveLocationIndex = Math.floor(
                clampedProgress * (photoClusters.length - 0.5),
            );
        } else {
            // Desktop: Use original logic
            currentActiveLocationIndex = Math.round(
                clampedProgress * Math.max(0, photoClusters.length - 1),
            );
        }
    }
    const previousActiveLocationIndex = previousActiveLocationRef.current;

    // Only pan map when active location changes (discrete panning)
    if (
        mapRef?.getContainer() &&
        currentActiveLocationIndex !== previousActiveLocationIndex
    ) {
        previousActiveLocationRef.current = currentActiveLocationIndex;

        // Skip panning if no location is selected (mobile default view)
        if (currentActiveLocationIndex === -1) return;

        const clusterCenters = photoClusters.map((cluster) => {
            const avgLat =
                cluster.reduce((sum, p) => sum + p.lat, 0) / cluster.length;
            const avgLng =
                cluster.reduce((sum, p) => sum + p.lng, 0) / cluster.length;
            return { lat: avgLat, lng: avgLng };
        });

        const targetCluster = clusterCenters[currentActiveLocationIndex];
        if (!targetCluster) return;

        // Position active location at 20% from right edge
        const [positionedLat, positionedLng] = getLocationPosition(
            targetCluster.lat,
            targetCluster.lng,
        );

        // Check if this is a distant location (>500km from previous)
        let isDistantLocation = false;
        const isFirstLocationEver = previousActiveLocationIndex === -1;
        if (
            previousActiveLocationIndex !== -1 &&
            previousActiveLocationIndex !== currentActiveLocationIndex
        ) {
            const previousCluster = clusterCenters[previousActiveLocationIndex];
            if (previousCluster) {
                const distance = calculateDistance(
                    previousCluster.lat,
                    previousCluster.lng,
                    targetCluster.lat,
                    targetCluster.lng,
                );
                isDistantLocation = distance > 500; // 500km threshold
            }
        }

        const targetZoom = isTouchDevice ? 8 : 10; // Touch device-aware zoom level

        // Use pre-calculated super cluster info instead of recalculating
        const currentSuperClusterIndex =
            superClusterInfo.clusterToSuperClusterMap.get(
                currentActiveLocationIndex,
            ) ?? -1;
        const isInSuperCluster = currentSuperClusterIndex !== -1;

        // Check previous super cluster state
        const previousState = previousSuperClusterStateRef.current;
        const wasInSuperCluster = previousState.isInSuperCluster;
        const previousSuperClusterIndex = previousState.superClusterIndex;
        const isSameSuperCluster =
            isInSuperCluster &&
            wasInSuperCluster &&
            currentSuperClusterIndex === previousSuperClusterIndex;

        try {
            // Handle super cluster zoom logic - check distant locations first!
            if (isInSuperCluster && !wasInSuperCluster && isFirstLocationEver) {
                // First location ever and it's in a super cluster - directly zoom to super cluster level
                const superClusterZoom = isTouchDevice ? 15 : 14; // Higher zoom on mobile to break apart clusters
                const [zoomAwareLat, zoomAwareLng] = getLocationPositionAtZoom(
                    targetCluster.lat,
                    targetCluster.lng,
                    superClusterZoom,
                );
                setTargetZoom(superClusterZoom);
                mapRef.setView([zoomAwareLat, zoomAwareLng], superClusterZoom);
            } else if (
                isInSuperCluster &&
                !wasInSuperCluster &&
                isDistantLocation
            ) {
                // Entering super cluster from distant location - full zoom out → pan → zoom in
                const superClusterZoom = isTouchDevice ? 15 : 14; // Higher zoom on mobile to break apart clusters
                const intermediateZoom = isTouchDevice ? 2 : 4; // Extreme zoom out for distant locations
                const [zoomAwareLat, zoomAwareLng] = getLocationPositionAtZoom(
                    targetCluster.lat,
                    targetCluster.lng,
                    superClusterZoom,
                );

                // First zoom out far for distant locations
                mapRef.flyTo([zoomAwareLat, zoomAwareLng], intermediateZoom, {
                    animate: true,
                    duration: 1.5,
                    easeLinearity: 0.25,
                });

                // Then zoom back in to super cluster level
                setTimeout(() => {
                    setTargetZoom(superClusterZoom);
                    mapRef.flyTo(
                        [zoomAwareLat, zoomAwareLng],
                        superClusterZoom,
                        { animate: true, duration: 1.2, easeLinearity: 0.25 },
                    );
                }, 1600);
            } else if (isInSuperCluster && !wasInSuperCluster) {
                // Entering super cluster from nearby location - direct zoom in
                const superClusterZoom = isTouchDevice ? 15 : 14; // Higher zoom on mobile to break apart clusters
                const [zoomAwareLat, zoomAwareLng] = getLocationPositionAtZoom(
                    targetCluster.lat,
                    targetCluster.lng,
                    superClusterZoom,
                );
                setTargetZoom(superClusterZoom);
                mapRef.flyTo([zoomAwareLat, zoomAwareLng], superClusterZoom, {
                    animate: true,
                    duration: 1.2,
                    easeLinearity: 0.3,
                });
            } else if (!isInSuperCluster && wasInSuperCluster) {
                // Leaving super cluster - check if distant location
                if (isDistantLocation) {
                    // Distant location: full zoom out → pan → zoom in
                    const intermediateZoom = isTouchDevice ? 2 : 4;
                    mapRef.flyTo(
                        [positionedLat, positionedLng],
                        intermediateZoom,
                        { animate: true, duration: 1.5, easeLinearity: 0.25 },
                    );

                    setTimeout(() => {
                        setTargetZoom(targetZoom);
                        mapRef.flyTo(
                            [positionedLat, positionedLng],
                            targetZoom,
                            {
                                animate: true,
                                duration: 1.2,
                                easeLinearity: 0.25,
                            },
                        );
                    }, 1600);
                } else {
                    // Nearby location: direct zoom out to normal view
                    setTargetZoom(targetZoom);
                    mapRef.flyTo([positionedLat, positionedLng], targetZoom, {
                        animate: true,
                        duration: 1.2,
                        easeLinearity: 0.3,
                    });
                }
            } else if (isSameSuperCluster) {
                // Moving within same super cluster - pan to zoom-aware positioned location, keep zoom
                const currentMapZoom = mapRef.getZoom();
                const [zoomAwareLat, zoomAwareLng] = getLocationPositionAtZoom(
                    targetCluster.lat,
                    targetCluster.lng,
                    currentMapZoom,
                );
                mapRef.panTo([zoomAwareLat, zoomAwareLng], {
                    animate: true,
                    duration: 0.6,
                    easeLinearity: 0.3,
                });
            } else if (isInSuperCluster) {
                // In super cluster but different from previous - treat as distant location
                // Check if we're switching between different super clusters
                const isDifferentSuperCluster =
                    wasInSuperCluster &&
                    currentSuperClusterIndex !== previousSuperClusterIndex;

                if (isDistantLocation) {
                    // Distant location from super cluster: full zoom out → pan → zoom in
                    // Since we're in the isInSuperCluster block, destination is always a super cluster
                    const finalZoom = isTouchDevice ? 15 : 14; // Higher zoom on mobile to break apart clusters
                    const intermediateZoom = isTouchDevice ? 2 : 4; // Extreme zoom out for distant locations
                    const [zoomAwareLat, zoomAwareLng] =
                        getLocationPositionAtZoom(
                            targetCluster.lat,
                            targetCluster.lng,
                            finalZoom,
                        );

                    // First zoom out far for distant locations
                    mapRef.flyTo(
                        [zoomAwareLat, zoomAwareLng],
                        intermediateZoom,
                        { animate: true, duration: 1.5, easeLinearity: 0.25 },
                    );

                    // Then zoom back in to appropriate level (super cluster or normal)
                    setTimeout(() => {
                        setTargetZoom(finalZoom);
                        mapRef.flyTo([zoomAwareLat, zoomAwareLng], finalZoom, {
                            animate: true,
                            duration: 1.2,
                            easeLinearity: 0.25,
                        });
                    }, 1600);
                } else if (isDifferentSuperCluster) {
                    // Different super cluster (not distant): moderate zoom out → pan → zoom in
                    const superClusterZoom = isTouchDevice ? 15 : 14; // Higher zoom on mobile to break apart clusters
                    const intermediateZoom = isTouchDevice ? 8 : 10; // Moderate zoom out for nearby super clusters
                    const [zoomAwareLat, zoomAwareLng] =
                        getLocationPositionAtZoom(
                            targetCluster.lat,
                            targetCluster.lng,
                            superClusterZoom,
                        );

                    // First zoom out moderately
                    mapRef.flyTo(
                        [zoomAwareLat, zoomAwareLng],
                        intermediateZoom,
                        { animate: true, duration: 0.8, easeLinearity: 0.25 },
                    );

                    // Then zoom back in to super cluster level
                    setTimeout(() => {
                        setTargetZoom(superClusterZoom);
                        mapRef.flyTo(
                            [zoomAwareLat, zoomAwareLng],
                            superClusterZoom,
                            {
                                animate: true,
                                duration: 0.8,
                                easeLinearity: 0.25,
                            },
                        );
                    }, 900);
                } else {
                    // Same super cluster, different location - just pan with zoom-aware positioning
                    const currentMapZoom = mapRef.getZoom();
                    const [zoomAwareLat, zoomAwareLng] =
                        getLocationPositionAtZoom(
                            targetCluster.lat,
                            targetCluster.lng,
                            currentMapZoom,
                        );
                    mapRef.panTo([zoomAwareLat, zoomAwareLng], {
                        animate: true,
                        duration: 0.6,
                        easeLinearity: 0.3,
                    });
                }
            } else if (isDistantLocation) {
                // For distant locations not in super cluster: zoom out → pan → zoom in
                const intermediateZoom = isTouchDevice ? 2 : 4;
                mapRef.flyTo([positionedLat, positionedLng], intermediateZoom, {
                    animate: true,
                    duration: 1.5,
                    easeLinearity: 0.25,
                });

                setTimeout(() => {
                    mapRef.flyTo([positionedLat, positionedLng], targetZoom, {
                        animate: true,
                        duration: 1.2,
                        easeLinearity: 0.25,
                    });
                }, 1600);
            } else {
                // For nearby locations not in super cluster: simple pan to target location
                const currentMapZoom = mapRef.getZoom();
                if (Math.abs(currentMapZoom - targetZoom) > 0.5) {
                    mapRef.flyTo([positionedLat, positionedLng], targetZoom, {
                        animate: true,
                        duration: 0.8,
                        easeLinearity: 0.3,
                    });
                } else {
                    mapRef.panTo([positionedLat, positionedLng], {
                        animate: true,
                        duration: 0.8,
                        easeLinearity: 0.3,
                    });
                }
            }

            // Update super cluster state
            previousSuperClusterStateRef.current = {
                isInSuperCluster,
                superClusterIndex: currentSuperClusterIndex,
            };
        } catch (error) {
            console.warn("Map operation failed:", error);
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

    // Check if we're on a touch device
    const isTouchDevice =
        typeof window !== "undefined" &&
        ("ontouchstart" in window || navigator.maxTouchPoints > 0);

    // Calculate target progress using the same formula as scroll progress calculation
    let targetProgress;
    if (isTouchDevice) {
        // Mobile: Use inverse of the slower progression formula
        // If active index = Math.floor(progress * (length - 0.5))
        // Then progress = (index + 0.5) / (length - 0.5) for accurate inverse
        targetProgress =
            (locationIndex + 0.5) / Math.max(1, photoClusters.length - 0.5);
    } else {
        // Desktop: Use original formula
        targetProgress = locationIndex / Math.max(1, photoClusters.length - 1);
    }

    // Clamp progress to valid range
    targetProgress = Math.min(1, Math.max(0, targetProgress));
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
    mapRef: import("leaflet").Map | null;
    isClusterClickScrollingRef: React.RefObject<boolean>;
    clusterClickTimeoutRef: React.RefObject<NodeJS.Timeout | null>;
    setScrollProgress: (progress: number) => void;
    setHasUserScrolled: (scrolled: boolean) => void;
    scrollTimelineToLocation: (locationIndex: number) => void;
    isTouchDevice: boolean;
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
    scrollProgress: number;
}

export const handleMarkerClick = ({
    clusterIndex,
    clusterLat,
    clusterLng,
    photoClusters,
    mapRef,
    isClusterClickScrollingRef,
    clusterClickTimeoutRef,
    setScrollProgress,
    setHasUserScrolled,
    scrollTimelineToLocation,
    isTouchDevice,
    superClusterInfo,
    scrollProgress,
}: HandleMarkerClickParams) => {
    const targetProgress = clusterIndex / Math.max(1, photoClusters.length - 1);

    if (clusterClickTimeoutRef.current) {
        clearTimeout(clusterClickTimeoutRef.current);
    }

    isClusterClickScrollingRef.current = true;
    setScrollProgress(targetProgress);
    setHasUserScrolled(true);

    // Calculate current active location index
    let currentActiveLocationIndex = -1;
    if (photoClusters.length > 0) {
        if (isTouchDevice) {
            currentActiveLocationIndex = Math.floor(
                scrollProgress * (photoClusters.length - 0.5),
            );
        } else {
            currentActiveLocationIndex = Math.round(
                scrollProgress * Math.max(0, photoClusters.length - 1),
            );
        }
    }

    // Check if both current and target locations are in the same super cluster
    let shouldJustPan = false;
    if (superClusterInfo && currentActiveLocationIndex >= 0) {
        const currentSuperClusterIndex =
            superClusterInfo.clusterToSuperClusterMap.get(
                currentActiveLocationIndex,
            );
        const targetSuperClusterIndex =
            superClusterInfo.clusterToSuperClusterMap.get(clusterIndex);

        // If both locations are in super clusters and they're the same super cluster
        shouldJustPan =
            currentSuperClusterIndex !== undefined &&
            targetSuperClusterIndex !== undefined &&
            currentSuperClusterIndex === targetSuperClusterIndex;
    }

    if (mapRef?.getContainer()) {
        try {
            if (shouldJustPan) {
                // Just pan to the location with zoom-aware positioning, keeping current zoom
                const currentMapZoom = mapRef.getZoom();
                const [zoomAwareLat, zoomAwareLng] = getLocationPositionAtZoom(
                    clusterLat,
                    clusterLng,
                    currentMapZoom,
                );
                mapRef.panTo([zoomAwareLat, zoomAwareLng], {
                    animate: true,
                    duration: 0.6,
                    easeLinearity: 0.3,
                });
            } else {
                // Normal behavior: fly to with zoom
                const [positionedLat, positionedLng] = getLocationPosition(
                    clusterLat,
                    clusterLng,
                );
                const targetZoom = isTouchDevice ? 8 : 10;
                mapRef.flyTo([positionedLat, positionedLng], targetZoom, {
                    animate: true,
                    duration: 1.0,
                    easeLinearity: 0.3,
                });
            }
        } catch (error) {
            console.warn("Map operation failed:", error);
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
