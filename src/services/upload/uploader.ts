import { EnteFile } from 'types/file';
import { handleUploadError, CustomError } from 'utils/error';
import { decryptFile } from 'utils/file';
import { logError } from 'utils/sentry';
import { fileAlreadyInCollection } from 'utils/upload';
import UploadHttpClient from './uploadHttpClient';
import UIService from './uiService';
import UploadService from './uploadService';
import {
    BackupedFile,
    EncryptedFile,
    FileInMemory,
    FileTypeInfo,
    FileWithCollection,
    FileWithMetadata,
    Metadata,
    UploadFile,
} from 'types/upload';
import { FileUploadResults } from 'constants/upload';

const FIVE_GB_IN_BYTES = 5 * 1024 * 1024 * 1024;
interface UploadResponse {
    fileUploadResult: FileUploadResults;
    file?: EnteFile;
}
export default async function uploader(
    worker: any,
    reader: FileReader,
    existingFilesInCollection: EnteFile[],
    fileWithCollection: FileWithCollection
): Promise<UploadResponse> {
    const {
        collection,
        key: progressBarKey,
        ...uploadAsset
    } = fileWithCollection;

    let file: FileInMemory = null;
    let encryptedFile: EncryptedFile = null;
    let metadata: Metadata = null;
    let fileTypeInfo: FileTypeInfo = null;
    let fileWithMetadata: FileWithMetadata = null;

    UIService.setFileProgress(progressBarKey, 0);
    const fileSize = UploadService.getAssetSize(uploadAsset);
    try {
        if (fileSize >= FIVE_GB_IN_BYTES) {
            return { fileUploadResult: FileUploadResults.TOO_LARGE };
        }

        fileTypeInfo = await UploadService.getAssetType(worker, uploadAsset);

        metadata = await UploadService.getAssetMetadata(
            uploadAsset,
            collection,
            fileTypeInfo
        );

        if (fileAlreadyInCollection(existingFilesInCollection, metadata)) {
            return { fileUploadResult: FileUploadResults.ALREADY_UPLOADED };
        }

        file = await UploadService.readAsset(
            worker,
            reader,
            fileTypeInfo,
            uploadAsset
        );

        if (file.hasStaticThumbnail) {
            metadata.hasStaticThumbnail = true;
        }
        fileWithMetadata = {
            filedata: file.filedata,
            thumbnail: file.thumbnail,
            metadata,
        };

        encryptedFile = await UploadService.encryptAsset(
            worker,
            fileWithMetadata,
            collection.key
        );

        const backupedFile: BackupedFile = await UploadService.uploadToBucket(
            encryptedFile.file
        );

        const uploadFile: UploadFile = UploadService.getUploadFile(
            collection,
            backupedFile,
            encryptedFile.fileKey
        );

        const uploadedFile = await UploadHttpClient.uploadFile(uploadFile);
        const decryptedFile = await decryptFile(uploadedFile, collection.key);

        UIService.increaseFileUploaded();
        return {
            fileUploadResult: FileUploadResults.UPLOADED,
            file: decryptedFile,
        };
    } catch (e) {
        logError(e, 'file upload failed', {
            fileFormat: fileTypeInfo.exactType,
        });
        const error = handleUploadError(e);
        switch (error.message) {
            case CustomError.ETAG_MISSING:
                return { fileUploadResult: FileUploadResults.BLOCKED };
            case CustomError.UNSUPPORTED_FILE_FORMAT:
                return { fileUploadResult: FileUploadResults.UNSUPPORTED };
            case CustomError.FILE_TOO_LARGE:
                return {
                    fileUploadResult:
                        FileUploadResults.LARGER_THAN_AVAILABLE_STORAGE,
                };
            default:
                return { fileUploadResult: FileUploadResults.FAILED };
        }
    } finally {
        file = null;
        fileWithMetadata = null;
        encryptedFile = null;
    }
}
