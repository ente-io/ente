import downloadManager from 'services/downloadManager';
import { fileAttribute, FILE_TYPE, getLocalFiles } from 'services/fileService';
import {
    generateThumbnail,
    MAX_THUMBNAIL_SIZE,
} from 'services/upload/thumbnailService';
import { getToken } from 'utils/common/key';
import { logError } from 'utils/sentry';
import { getEndpoint } from 'utils/common/apiUtil';
import HTTPService from 'services/HTTPService';
import CryptoWorker from 'utils/crypto';
import uploadHttpClient from 'services/upload/uploadHttpClient';
import { EncryptionResult, UploadURL } from 'services/upload/uploadService';
import { SetProgressTracker } from 'components/FixLargeThumbnail';

const ENDPOINT = getEndpoint();

export async function getLargeThumbnailFiles() {
    try {
        const token = getToken();
        if (!token) {
            return;
        }
        const resp = await HTTPService.get(
            `${ENDPOINT}/files/large-thumbnails`,
            {
                threshold: 2 * MAX_THUMBNAIL_SIZE,
            },
            {
                'X-Auth-Token': token,
            }
        );
        return resp.data.largeThumbnailFiles as number[];
    } catch (e) {
        logError(e, 'failed to get large thumbnail files');
        throw e;
    }
}
export async function replaceThumbnail(setProgressTracker: SetProgressTracker) {
    let completedWithError = false;
    try {
        const token = getToken();
        const worker = await new CryptoWorker();
        const largeThumbnailFileIDs = new Set(
            (await getLargeThumbnailFiles()) ?? []
        );
        const files = await getLocalFiles();
        const largeThumbnailFiles = files.filter((file) =>
            largeThumbnailFileIDs.has(file.id)
        );

        if (largeThumbnailFiles.length === 0) {
            return completedWithError;
        }
        setProgressTracker({ current: 0, total: largeThumbnailFiles.length });
        const uploadURLs: UploadURL[] = [];
        uploadHttpClient.fetchUploadURLs(
            largeThumbnailFiles.length,
            uploadURLs
        );
        for (const [idx, file] of largeThumbnailFiles.entries()) {
            try {
                setProgressTracker({
                    current: idx,
                    total: largeThumbnailFiles.length,
                });
                const originalThumbnail = await downloadManager.getThumbnail(
                    token,
                    file
                );
                const dummyImageFile = new globalThis.File(
                    [originalThumbnail],
                    file.metadata.title
                );
                const { thumbnail: newThumbnail } = await generateThumbnail(
                    worker,
                    dummyImageFile,
                    FILE_TYPE.IMAGE,
                    false
                );
                const newUploadedThumbnail = await uploadThumbnail(
                    worker,
                    file.key,
                    newThumbnail,
                    uploadURLs.pop()
                );
                await updateThumbnail(file.id, newUploadedThumbnail);
            } catch (e) {
                logError(e, 'failed to replace a thumbnail');
                completedWithError = true;
            }
        }
    } catch (e) {
        logError(e, 'replace Thumbnail function failed');
        completedWithError = true;
    }
    return completedWithError;
}

export async function uploadThumbnail(
    worker,
    fileKey: string,
    updatedThumbnail: Uint8Array,
    uploadURL: UploadURL
): Promise<fileAttribute> {
    const { file: encryptedThumbnail }: EncryptionResult =
        await worker.encryptThumbnail(updatedThumbnail, fileKey);

    const thumbnailObjectKey = await uploadHttpClient.putFile(
        uploadURL,
        encryptedThumbnail.encryptedData as Uint8Array,
        () => {}
    );
    return {
        objectKey: thumbnailObjectKey,
        decryptionHeader: encryptedThumbnail.decryptionHeader,
    };
}

export async function updateThumbnail(
    fileID: number,
    newThumbnail: fileAttribute
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
                'X-Auth-Token': token,
            }
        );
    } catch (e) {
        logError(e, 'failed to update thumbnail');
        throw e;
    }
}
