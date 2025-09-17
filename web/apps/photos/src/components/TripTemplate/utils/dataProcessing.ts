import { downloadManager } from "ente-gallery/services/download";
import { type EnteFile } from "ente-media/file";
import { fileFileName } from "ente-media/file-metadata";
import React from "react";

import type { JourneyPoint } from "../types";
import { getLocationName } from "./geocoding";

export interface ProcessPhotosDataParams {
    files: EnteFile[];
    locationDataRef: React.RefObject<
        Map<number, { name: string; country: string }>
    >;
}

export interface ProcessPhotosDataResult {
    photoData: JourneyPoint[];
    hasLocationData: boolean;
}

export const processPhotosData = ({
    files,
    locationDataRef,
}: ProcessPhotosDataParams): ProcessPhotosDataResult => {
    const photoData: JourneyPoint[] = [];

    if (files.length === 0) {
        return { photoData, hasLocationData: false };
    }

    for (const file of files) {
        try {
            const lat = file.metadata.latitude;
            const lng = file.metadata.longitude;

            if (lat && lng) {
                const cachedLocation = locationDataRef.current.get(file.id);
                const finalName = cachedLocation?.name || fileFileName(file);
                const finalCountry = cachedLocation?.country || "Unknown";

                photoData.push({
                    lat: lat,
                    lng: lng,
                    name: finalName,
                    country: finalCountry,
                    timestamp: new Date(
                        file.metadata.creationTime / 1000,
                    ).toISOString(),
                    image: "",
                    fileId: file.id,
                });
            }
        } catch {
            // Silently ignore processing errors for individual files
        }
    }

    photoData.sort(
        (a, b) =>
            new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime(),
    );

    return { photoData, hasLocationData: photoData.length > 0 };
};

export interface FetchLocationNamesParams {
    photoClusters: JourneyPoint[][];
    journeyData: JourneyPoint[];
    locationDataRef: React.RefObject<
        Map<number, { name: string; country: string }>
    >;
}

export interface FetchLocationNamesResult {
    updatedPhotos: Map<number, { name: string; country: string }>;
}

export const fetchLocationNames = async ({
    photoClusters,
    locationDataRef,
}: FetchLocationNamesParams): Promise<FetchLocationNamesResult> => {
    const updatedPhotos = new Map<number, { name: string; country: string }>();

    if (photoClusters.length === 0) {
        return { updatedPhotos };
    }

    for (let i = 0; i < photoClusters.length; i++) {
        const cluster = photoClusters[i];
        if (!cluster || cluster.length === 0) continue;

        const avgLat =
            cluster.reduce((sum, p) => sum + p.lat, 0) / cluster.length;
        const avgLng =
            cluster.reduce((sum, p) => sum + p.lng, 0) / cluster.length;

        try {
            const locationInfo = await getLocationName(avgLat, avgLng, i + 1);

            cluster.forEach((photo) => {
                updatedPhotos.set(photo.fileId, {
                    name: locationInfo.place,
                    country: locationInfo.country,
                });
                locationDataRef.current.set(photo.fileId, {
                    name: locationInfo.place,
                    country: locationInfo.country,
                });
            });
        } catch {
            // Silently ignore processing errors for individual files
        }
    }

    return { updatedPhotos };
};

export interface GenerateThumbnailsParams {
    photoClusters: JourneyPoint[][];
    files: EnteFile[];
}

export interface GenerateThumbnailsResult {
    thumbnailUpdates: Map<number, string>;
}

export const generateNeededThumbnails = async ({
    photoClusters,
    files,
}: GenerateThumbnailsParams): Promise<GenerateThumbnailsResult> => {
    const thumbnailUpdates = new Map<number, string>();

    if (photoClusters.length === 0) {
        return { thumbnailUpdates };
    }

    // Define priority groups with specific file collections
    const priorityGroups: EnteFile[][] = [];

    // Priority 1: Cover image (handled separately in loadCoverImage, skip here)

    // Priority 2: First 3 locations photosfans (first 3 photos from each)
    const firstLocationsFiles: EnteFile[] = [];
    photoClusters.slice(0, 3).forEach((cluster) => {
        cluster.slice(0, 3).forEach((photo) => {
            const file = files.find((f) => f.id === photo.fileId);
            if (file && !firstLocationsFiles.includes(file)) {
                firstLocationsFiles.push(file);
            }
        });
    });
    if (firstLocationsFiles.length > 0) {
        priorityGroups.push(firstLocationsFiles);
    }

    // Priority 3: Map marker photos (first photo from each cluster for markers)
    const mapMarkerFiles: EnteFile[] = [];
    photoClusters.forEach((cluster) => {
        if (cluster.length > 0 && cluster[0]) {
            const firstPhoto = cluster[0];
            const file = files.find((f) => f.id === firstPhoto.fileId);
            if (
                file &&
                !firstLocationsFiles.includes(file) &&
                !mapMarkerFiles.includes(file)
            ) {
                mapMarkerFiles.push(file);
            }
        }
    });
    if (mapMarkerFiles.length > 0) {
        priorityGroups.push(mapMarkerFiles);
    }

    // Priority 4: Rest of locations photosfans (remaining locations, first 3 from each)
    const remainingLocationFiles: EnteFile[] = [];
    photoClusters.slice(3).forEach((cluster) => {
        cluster.slice(0, 3).forEach((photo) => {
            const file = files.find((f) => f.id === photo.fileId);
            if (
                file &&
                !firstLocationsFiles.includes(file) &&
                !mapMarkerFiles.includes(file) &&
                !remainingLocationFiles.includes(file)
            ) {
                remainingLocationFiles.push(file);
            }
        });
    });
    if (remainingLocationFiles.length > 0) {
        priorityGroups.push(remainingLocationFiles);
    }

    // Process priority groups sequentially with delays
    for (let groupIndex = 0; groupIndex < priorityGroups.length; groupIndex++) {
        const group = priorityGroups[groupIndex];
        if (!group) continue;

        // Process files in parallel within each priority group
        const groupPromises = group.map(async (file) => {
            try {
                const thumbnailUrl =
                    await downloadManager.renderableThumbnailURL(file);
                if (thumbnailUrl) {
                    thumbnailUpdates.set(file.id, thumbnailUrl);
                }
            } catch {
                // Silently ignore thumbnail generation errors
            }
        });

        await Promise.all(groupPromises);

        // Add small delay between priority groups to allow UI updates
        if (groupIndex < priorityGroups.length - 1) {
            await new Promise((resolve) => setTimeout(resolve, 50));
        }
    }

    return { thumbnailUpdates };
};

export interface LoadCoverImageParams {
    journeyData: JourneyPoint[];
    files: EnteFile[];
    collection?: { pubMagicMetadata?: { data: { coverID?: number } } };
}

export const loadCoverImage = async ({
    journeyData,
    files,
    collection,
}: LoadCoverImageParams): Promise<string | null> => {
    if (journeyData.length === 0) return null;

    let coverFile: EnteFile | undefined;

    // Priority 1: Use explicit cover ID if set
    const coverID = collection?.pubMagicMetadata?.data.coverID;
    if (coverID) {
        coverFile = files.find((f) => f.id === coverID);
    }

    // Priority 2: Use first chronological photo as cover (highest priority)
    if (!coverFile) {
        const firstPhoto = journeyData[0];
        if (!firstPhoto) return null;
        coverFile = files.find((f) => f.id === firstPhoto.fileId);
    }

    if (!coverFile) return null;

    try {
        // Load cover image at highest quality first (highest priority)
        const sourceURLs =
            await downloadManager.renderableSourceURLs(coverFile);
        if (sourceURLs.type === "image") {
            return sourceURLs.imageURL;
        }
    } catch {
        // Keep using thumbnail if high quality fails
    }

    return null;
};
