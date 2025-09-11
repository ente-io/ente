import { useEffect } from "react";

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
    // Fetch location names for clusters
    useEffect(() => {
        const fetchNames = async () => {
            if (photoClusters.length === 0) return;

            setIsLoadingLocations(true);

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
            } finally {
                setIsLoadingLocations(false);
            }
        };

        void fetchNames();
    }, [
        photoClusters.length,
        locationDataRef,
        setJourneyData,
        setIsLoadingLocations,
    ]);
};
