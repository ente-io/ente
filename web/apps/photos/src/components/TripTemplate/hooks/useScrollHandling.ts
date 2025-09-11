import { useCallback, useEffect, useMemo } from "react";

import type { JourneyPoint } from "../types";
import { throttle } from "../utils/geocoding";
import {
    updateLocationPositions,
    handleTimelineScroll,
    scrollTimelineToLocation,
    handleMarkerClick,
    type PositionInfo,
} from "../utils/scrollUtils";

export interface UseScrollHandlingParams {
    timelineRef: React.RefObject<HTMLDivElement | null>;
    photoClusters: JourneyPoint[][];
    locationPositions: PositionInfo[];
    mapRef: L.Map | null;
    screenDimensions: { width: number; height: number };
    optimalZoom: number;
    locationRefs: React.MutableRefObject<(HTMLDivElement | null)[]>;
    isClusterClickScrollingRef: React.MutableRefObject<boolean>;
    clusterClickTimeoutRef: React.MutableRefObject<NodeJS.Timeout | null>;
    setLocationPositions: (positions: PositionInfo[]) => void;
    setHasUserScrolled: (scrolled: boolean) => void;
    setScrollProgress: (progress: number) => void;
}

export const useScrollHandling = ({
    timelineRef,
    photoClusters,
    locationPositions,
    mapRef,
    screenDimensions,
    optimalZoom,
    locationRefs,
    isClusterClickScrollingRef,
    clusterClickTimeoutRef,
    setLocationPositions,
    setHasUserScrolled,
    setScrollProgress,
}: UseScrollHandlingParams) => {
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
            screenDimensions,
            optimalZoom,
            isClusterClickScrollingRef,
            setHasUserScrolled,
            setScrollProgress,
        });
    }, [
        timelineRef,
        photoClusters,
        locationPositions,
        mapRef,
        screenDimensions,
        optimalZoom,
        isClusterClickScrollingRef,
        setHasUserScrolled,
        setScrollProgress,
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
                screenDimensions,
                mapRef,
                optimalZoom,
                isClusterClickScrollingRef,
                clusterClickTimeoutRef,
                setScrollProgress,
                setHasUserScrolled,
                scrollTimelineToLocation: scrollToLocation,
            });
        },
        [
            photoClusters,
            screenDimensions,
            mapRef,
            optimalZoom,
            isClusterClickScrollingRef,
            clusterClickTimeoutRef,
            setScrollProgress,
            setHasUserScrolled,
            scrollToLocation,
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
            timelineContainer.removeEventListener("scroll", throttledTimelineScroll);
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

    return {
        updatePositions,
        scrollToLocation,
        markerClickHandler,
    };
};