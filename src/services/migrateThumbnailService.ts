import downloadManager from 'services/downloadManager';
import { getLocalFiles } from 'services/fileService';
import { generateThumbnail } from 'services/upload/thumbnailService';
import { getToken } from 'utils/common/key';
import { logError } from 'utils/sentry';
import { getEndpoint } from 'utils/common/apiUtil';
import HTTPService from 'services/HTTPService';
import CryptoWorker from 'utils/crypto';
import uploadHttpClient from 'services/upload/uploadHttpClient';
import { SetProgressTracker } from 'components/FixLargeThumbnail';
import { getFileType } from 'services/typeDetectionService';
import { getLocalTrash, getTrashedFiles } from './trashService';
import { EncryptionResult, UploadURL } from 'types/upload';
import { fileAttribute } from 'types/file';
import { USE_CF_PROXY } from 'constants/upload';

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
                'X-Auth-Token': token,
            }
        );
        return resp.data.largeThumbnailFiles as number[];
    } catch (e) {
        logError(e, 'failed to get large thumbnail files');
        throw e;
    }
}
export async function replaceThumbnail(
    setProgressTracker: SetProgressTracker,
    largeThumbnailFileIDs: Set<number>
) {
    let completedWithError = false;
    try {
        const token = getToken();
        const worker = await new CryptoWorker();
        const files = await getLocalFiles();
        const trash = await getLocalTrash();
        const trashFiles = getTrashedFiles(trash);
        const largeThumbnailFiles = [...files, ...trashFiles].filter((file) =>
            largeThumbnailFileIDs.has(file.id)
        );
        if (largeThumbnailFileIDs.size !== largeThumbnailFiles.length) {
            logError(Error(), 'all large thumbnail files not found locally');
        }
        if (largeThumbnailFiles.length === 0) {
            return completedWithError;
        }
        setProgressTracker({ current: 0, total: largeThumbnailFiles.length });
        const uploadURLs: UploadURL[] = [];
        await uploadHttpClient.fetchUploadURLs(
            largeThumbnailFiles.length,
            uploadURLs
        );
        for (const [idx, file] of largeThumbnailFiles.entries()) {
            try {
                setProgressTracker({
                    current: idx,
                    total: largeThumbnailFiles.length,
                });
                const originalThumbnail = await downloadManager.downloadThumb(
                    token,
                    file
                );
                const dummyImageFile = new File(
                    [originalThumbnail],
                    file.metadata.title
                );
                const fileTypeInfo = await getFileType(dummyImageFile);
                const { thumbnail: newThumbnail } = await generateThumbnail(
                    dummyImageFile,
                    fileTypeInfo
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
    let thumbnailObjectKey: string = null;
    if (USE_CF_PROXY) {
        thumbnailObjectKey = await uploadHttpClient.putFileV2(
            uploadURL,
            encryptedThumbnail.encryptedData as Uint8Array,
            () => {}
        );
    } else {
        thumbnailObjectKey = await uploadHttpClient.putFile(
            uploadURL,
            encryptedThumbnail.encryptedData as Uint8Array,
            () => {}
        );
    }
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
