import ComlinkCryptoWorker from "@ente/shared/crypto";
import { DedicatedCryptoWorker } from "@ente/shared/crypto/internal/crypto.worker";
import HTTPService from "@ente/shared/network/HTTPService";
import { getEndpoint } from "@ente/shared/network/api";
import { logError } from "@ente/shared/sentry";
import { getToken } from "@ente/shared/storage/localStorage/helpers";
import { Remote } from "comlink";
import { SetProgressTracker } from "components/FixLargeThumbnail";
import downloadManager from "services/download";
import { getLocalFiles } from "services/fileService";
import { getFileType } from "services/typeDetectionService";
import { generateThumbnail } from "services/upload/thumbnailService";
import uploadHttpClient from "services/upload/uploadHttpClient";
import { S3FileAttributes } from "types/file";
import { UploadURL } from "types/upload";
import { getLocalTrashedFiles } from "./trashService";

const ENDPOINT = getEndpoint();
const REPLACE_THUMBNAIL_THRESHOLD = 500 * 1024; // 500KB
export async function getLargeThumbnailFiles() {
    try {
        const token = getToken();
        if (!token) {
            return;
        }
        const resp = await HTTPService.get(
            `${ENDPOINT}/files/large-thumbnails`,
            {
                threshold: REPLACE_THUMBNAIL_THRESHOLD,
            },
            {
                "X-Auth-Token": token,
            },
        );
        return resp.data.largeThumbnailFiles as number[];
    } catch (e) {
        logError(e, "failed to get large thumbnail files");
        throw e;
    }
}
export async function replaceThumbnail(
    setProgressTracker: SetProgressTracker,
    largeThumbnailFileIDs: Set<number>,
) {
    let completedWithError = false;
    try {
        const cryptoWorker = await ComlinkCryptoWorker.getInstance();
        const files = await getLocalFiles();
        const trashFiles = await getLocalTrashedFiles();
        const largeThumbnailFiles = [...files, ...trashFiles].filter((file) =>
            largeThumbnailFileIDs.has(file.id),
        );
        if (largeThumbnailFileIDs.size !== largeThumbnailFiles.length) {
            logError(Error(), "all large thumbnail files not found locally");
        }
        if (largeThumbnailFiles.length === 0) {
            return completedWithError;
        }
        setProgressTracker({ current: 0, total: largeThumbnailFiles.length });
        const uploadURLs: UploadURL[] = [];
        await uploadHttpClient.fetchUploadURLs(
            largeThumbnailFiles.length,
            uploadURLs,
        );
        for (const [idx, file] of largeThumbnailFiles.entries()) {
            try {
                setProgressTracker({
                    current: idx,
                    total: largeThumbnailFiles.length,
                });
                const originalThumbnail =
                    await downloadManager.getThumbnail(file);
                const dummyImageFile = new File(
                    [originalThumbnail],
                    file.metadata.title,
                );
                const fileTypeInfo = await getFileType(dummyImageFile);
                const { thumbnail: newThumbnail } = await generateThumbnail(
                    dummyImageFile,
                    fileTypeInfo,
                );
                const newUploadedThumbnail = await uploadThumbnail(
                    cryptoWorker,
                    file.key,
                    newThumbnail,
                    uploadURLs.pop(),
                );
                await updateThumbnail(file.id, newUploadedThumbnail);
            } catch (e) {
                logError(e, "failed to replace a thumbnail");
                completedWithError = true;
            }
        }
    } catch (e) {
        logError(e, "replace Thumbnail function failed");
        completedWithError = true;
    }
    return completedWithError;
}

export async function uploadThumbnail(
    worker: Remote<DedicatedCryptoWorker>,
    fileKey: string,
    updatedThumbnail: Uint8Array,
    uploadURL: UploadURL,
): Promise<S3FileAttributes> {
    const { file: encryptedThumbnail } = await worker.encryptThumbnail(
        updatedThumbnail,
        fileKey,
    );
    const thumbnailObjectKey = await uploadHttpClient.putFile(
        uploadURL,
        encryptedThumbnail.encryptedData,
        () => {},
    );

    return {
        objectKey: thumbnailObjectKey,
        decryptionHeader: encryptedThumbnail.decryptionHeader,
    };
}

export async function updateThumbnail(
    fileID: number,
    newThumbnail: S3FileAttributes,
) {
    try {
        const token = getToken();
        if (!token) {
            return;
        }
        await HTTPService.put(
            `${ENDPOINT}/files/thumbnail`,
            {
                fileID: fileID,
                thumbnail: newThumbnail,
            },
            null,
            {
                "X-Auth-Token": token,
            },
        );
    } catch (e) {
        logError(e, "failed to update thumbnail");
        throw e;
    }
}
