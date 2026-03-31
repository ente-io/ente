import { basename, dirname } from "ente-base/file-name";
import log from "ente-base/log";
import { customAPIOrigin } from "ente-base/origins";
import { exportMetadataDirectoryName } from "@/gallery/export-dirs";
import type { Collection } from "ente-media/collection";
import type { EnteFile } from "ente-media/file";
import { nullToUndefined } from "ente-utils/transform";
import { z } from "zod";

class UploadState {
    shouldDisableCFUploadProxy = false;
    checksumProtectedUploadsEnabled = false;
}

const _state = new UploadState();

/**
 * The public albums uploader only handles browser-provided Files.
 */
export type UploadItem = File;

/**
 * Opaque folder-like context used when matching metadata JSON sidecars.
 */
export type UploadPathPrefix = string;

export const uploadPathPrefix = (pathOrName: string) => {
    const folderPath = dirname(pathOrName);
    if (basename(folderPath) == exportMetadataDirectoryName) {
        return dirname(folderPath);
    }
    return folderPath;
};

export interface LivePhotoAssets {
    image: File;
    video: File;
}

export interface ClusteredUploadItem {
    localID: number;
    collectionID: number;
    fileName: string;
    isLivePhoto: boolean;
    uploadItem?: UploadItem;
    pathPrefix: UploadPathPrefix | undefined;
    livePhotoAssets?: LivePhotoAssets;
}

export type UploadableUploadItem = ClusteredUploadItem & {
    collection: Collection;
};

export type UploadPhase =
    | "preparing"
    | "readingMetadata"
    | "uploading"
    | "cancelling"
    | "done";

export type UploadResult =
    | { type: "unsupported" }
    | { type: "zeroSize" }
    | { type: "tooLarge" }
    | { type: "largerThanAvailableStorage" }
    | { type: "blocked" }
    | { type: "failed" }
    | { type: "alreadyUploaded"; file: EnteFile }
    | { type: "uploadedWithStaticThumbnail"; file: EnteFile }
    | { type: "uploaded"; file: EnteFile };

export const shouldDisableCFUploadProxy = () =>
    _state.shouldDisableCFUploadProxy;

export const updateShouldDisableCFUploadProxy = async (
    savedPreference?: boolean,
) => {
    _state.shouldDisableCFUploadProxy =
        savedPreference || (await computeShouldDisableCFUploadProxy());
};

export const areChecksumProtectedUploadsEnabled = () =>
    _state.checksumProtectedUploadsEnabled;

const computeShouldDisableCFUploadProxy = async () => {
    if (await customAPIOrigin()) return true;

    try {
        const res = await fetch("https://static.ente.io/feature_flags.json");
        return (
            StaticFeatureFlags.parse(await res.json()).disableCFUploadProxy ??
            false
        );
    } catch (e) {
        log.warn("Ignoring error when getting feature_flags.json", e);
        return false;
    }
};

const StaticFeatureFlags = z.object({
    disableCFUploadProxy: z.boolean().nullish().transform(nullToUndefined),
});
