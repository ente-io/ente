import { useIsTouchscreen } from "ente-base/components/utils/hooks";
import { useCallback, useEffect, useMemo } from "react";

import type { JourneyPoint } from "../types";
import { throttle } from "../utils/geocoding";
import {
    handleMarkerClick,
    handleTimelineScroll,
    scrollTimelineToLocation,
    updateLocationPositions,
    type PositionInfo,
} from "../utils/scrollUtils";

export interface UseScrollHandlingParams {
    timelineRef: React.RefObject<HTMLDivElement | null>;
    photoClusters: JourneyPoint[][];
    locationPositions: PositionInfo[];
    mapRef: L.Map | null;
    locationRefs: React.RefObject<(HTMLDivElement | null)[]>;
    isClusterClickScrollingRef: React.RefObject<boolean>;
    clusterClickTimeoutRef: React.RefObject<NodeJS.Timeout | null>;
    previousActiveLocationRef: React.RefObject<number>;
    setLocationPositions: (positions: PositionInfo[]) => void;
    setHasUserScrolled: (scrolled: boolean) => void;
    setScrollProgress: (progress: number) => void;
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
    scrollProgress: number;
}

export const useScrollHandling = ({
    timelineRef,
    photoClusters,
    locationPositions,
    mapRef,
    locationRefs,
    isClusterClickScrollingRef,
    clusterClickTimeoutRef,
    previousActiveLocationRef,
    setLocationPositions,
    setHasUserScrolled,
    setScrollProgress,
    setTargetZoom,
    previousSuperClusterStateRef,
    superClusterInfo,
    scrollProgress,
}: UseScrollHandlingParams) => {
    const isTouchDevice = useIsTouchscreen();
    // Update location positions callback
    const updatePositions = useCallback(() => {
        updateLocationPositions({
            locationRefs: locationRefs.current,
            setLocationPositions,
        });
    }, [locationRefs, setLocationPositions]);

    // Timeline scroll handler
    const timelineScrollHandler = useCallback(() => {
        handleTimelineScroll({
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
        });
    }, [
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
    ]);

    // Throttled scroll handler
    const throttledTimelineScroll = useMemo(
        () => throttle(timelineScrollHandler, 16),
        [timelineScrollHandler],
    );

    // Timeline scroll to location function
    const scrollToLocation = useCallback(
        (locationIndex: number) => {
            scrollTimelineToLocation({
                timelineRef,
                locationIndex,
                photoClusters,
                locationPositions,
            });
        },
        [timelineRef, photoClusters, locationPositions],
    );

    // Marker click handler
    const markerClickHandler = useCallback(
        (clusterIndex: number, clusterLat: number, clusterLng: number) => {
            handleMarkerClick({
                clusterIndex,
                clusterLat,
                clusterLng,
                photoClusters,
                mapRef,
                isClusterClickScrollingRef,
                clusterClickTimeoutRef,
                setScrollProgress,
                setHasUserScrolled,
                scrollTimelineToLocation: scrollToLocation,
                isTouchDevice,
                superClusterInfo,
                scrollProgress,
            });
        },
        [
            photoClusters,
            mapRef,
            isClusterClickScrollingRef,
            clusterClickTimeoutRef,
            setScrollProgress,
            setHasUserScrolled,
            scrollToLocation,
            isTouchDevice,
            superClusterInfo,
            scrollProgress,
        ],
    );

    // Update positions when locations render
    useEffect(() => {
        if (
            locationRefs.current.length === photoClusters.length &&
            photoClusters.length > 0
        ) {
            const timer = setTimeout(updatePositions, 100);
            return () => clearTimeout(timer);
        }
        return undefined;
    }, [photoClusters, updatePositions, locationRefs]);

    // Add scroll event listener
    useEffect(() => {
        const timelineContainer = timelineRef.current;
        if (!timelineContainer) return;

        timelineContainer.addEventListener("scroll", throttledTimelineScroll);

        return () => {
            timelineContainer.removeEventListener(
                "scroll",
                throttledTimelineScroll,
            );
        };
    }, [throttledTimelineScroll, timelineRef]);

    // Cleanup timeout on unmount
    useEffect(() => {
        return () => {
            if (clusterClickTimeoutRef.current) {
                clearTimeout(clusterClickTimeoutRef.current);
                clusterClickTimeoutRef.current = null;
            }
        };
    }, [clusterClickTimeoutRef]);

    return { updatePositions, scrollToLocation, markerClickHandler };
};
