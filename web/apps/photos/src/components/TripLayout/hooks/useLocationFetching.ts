import { useEffect, useRef } from "react";

import type { JourneyPoint } from "../types";
import { fetchLocationNames } from "../utils/dataProcessing";

export interface UseLocationFetchingParams {
    photoClusters: JourneyPoint[][];
    journeyData: JourneyPoint[];
    locationDataRef: React.RefObject<
        Map<number, { name: string; country: string }>
    >;
    setJourneyData: (
        data: JourneyPoint[] | ((prev: JourneyPoint[]) => JourneyPoint[]),
    ) => void;
    setIsLoadingLocations: (loading: boolean) => void;
}

export const useLocationFetching = ({
    photoClusters,
    locationDataRef,
    setJourneyData,
    setIsLoadingLocations,
}: UseLocationFetchingParams) => {
    const processedPhotoIdsRef = useRef<Set<number>>(new Set());
    const lastFetchedClustersRef = useRef<string>("");

    // Fetch location names for clusters
    useEffect(() => {
        // Create a stable key for current clusters to prevent duplicate fetches
        const clustersKey = photoClusters
            .map((cluster) => cluster.map((p) => p.fileId).join(","))
            .join("|");

        // Skip if we already fetched for these exact clusters
        if (clustersKey === lastFetchedClustersRef.current) {
            return;
        }

        const fetchNames = async () => {
            if (photoClusters.length === 0) return;

            // Get all current photo IDs
            const currentPhotoIds = new Set(
                photoClusters.flat().map((photo) => photo.fileId),
            );

            // Check if any photos need location fetching
            const needsFetching = photoClusters.some((cluster) =>
                cluster.some(
                    (photo) => !locationDataRef.current.has(photo.fileId),
                ),
            );

            if (!needsFetching) {
                setIsLoadingLocations(false);
                return;
            }

            setIsLoadingLocations(true);
            lastFetchedClustersRef.current = clustersKey;

            try {
                const { updatedPhotos } = await fetchLocationNames({
                    photoClusters,
                    journeyData: [],
                    locationDataRef,
                });

                if (updatedPhotos.size > 0) {
                    setJourneyData((prevData) =>
                        prevData.map((photo) => {
                            const update = updatedPhotos.get(photo.fileId);
                            if (update) {
                                return { ...photo, ...update };
                            }
                            return photo;
                        }),
                    );
                }

                // Update processed photos set
                processedPhotoIdsRef.current = currentPhotoIds;
            } finally {
                setIsLoadingLocations(false);
            }
        };

        void fetchNames();
    }, [photoClusters, locationDataRef, setJourneyData, setIsLoadingLocations]);
};
