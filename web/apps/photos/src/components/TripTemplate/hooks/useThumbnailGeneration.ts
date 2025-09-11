import { useEffect } from "react";
import { type EnteFile } from "ente-media/file";

import type { JourneyPoint } from "../types";
import { generateNeededThumbnails } from "../utils/dataProcessing";

export interface UseThumbnailGenerationParams {
    photoClusters: JourneyPoint[][];
    journeyData: JourneyPoint[];
    files: EnteFile[];
    thumbnailsGeneratedRef: React.MutableRefObject<boolean>;
    setJourneyData: (data: JourneyPoint[] | ((prev: JourneyPoint[]) => JourneyPoint[])) => void;
}

export const useThumbnailGeneration = ({
    photoClusters,
    files,
    thumbnailsGeneratedRef,
    setJourneyData,
}: UseThumbnailGenerationParams) => {
    // Generate thumbnails for needed photos with progressive loading
    useEffect(() => {
        const generateThumbs = async () => {
            if (photoClusters.length === 0 || thumbnailsGeneratedRef.current) return;

            const { thumbnailUpdates } = await generateNeededThumbnails({
                photoClusters,
                files,
            });

            if (thumbnailUpdates.size > 0) {
                setJourneyData((prevData) =>
                    prevData.map((photo) => {
                        const thumbnailUrl = thumbnailUpdates.get(photo.fileId);
                        if (thumbnailUrl && !photo.image) {
                            return { ...photo, image: thumbnailUrl };
                        }
                        return photo;
                    }),
                );
            }
            thumbnailsGeneratedRef.current = true;
        };

        void generateThumbs();
    }, [photoClusters.length, files, thumbnailsGeneratedRef, setJourneyData]);
};