import { EnteFile } from 'types/file';
import { handleUploadError, CustomError } from 'utils/error';
import { decryptFile } from 'utils/file';
import { logError } from 'utils/sentry';
import { fileAlreadyInCollection } from 'utils/upload';
import UploadHttpClient from './uploadHttpClient';
import UIService from './uiService';
import UploadService from './uploadService';
import { FILE_TYPE } from 'constants/file';
import { FileUploadResults, MAX_FILE_SIZE_SUPPORTED } from 'constants/upload';
import { FileWithCollection, BackupedFile, UploadFile } from 'types/upload';
import { logUploadInfo } from 'utils/upload';
import { convertToHumanReadable } from 'utils/billing';
import { sleep } from 'utils/common';

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
    const { collection, localID, ...uploadAsset } = fileWithCollection;
    const fileNameSize = `${UploadService.getAssetName(
        fileWithCollection
    )}_${convertToHumanReadable(UploadService.getAssetSize(uploadAsset))}`;

    logUploadInfo(`uploader called for  ${fileNameSize}`);
    UIService.setFileProgress(localID, 0);
    const { fileTypeInfo, metadata } =
        UploadService.getFileMetadataAndFileTypeInfo(localID);
    try {
        const fileSize = UploadService.getAssetSize(uploadAsset);
        if (fileSize >= MAX_FILE_SIZE_SUPPORTED) {
            return { fileUploadResult: FileUploadResults.TOO_LARGE };
        }
        if (fileTypeInfo.fileType === FILE_TYPE.OTHERS) {
            throw Error(CustomError.UNSUPPORTED_FILE_FORMAT);
        }
        if (!metadata) {
            throw Error(CustomError.NO_METADATA);
        }

        if (fileAlreadyInCollection(existingFilesInCollection, metadata)) {
            logUploadInfo(`skipped upload for  ${fileNameSize}`);
            return { fileUploadResult: FileUploadResults.ALREADY_UPLOADED };
        }
        logUploadInfo(`reading asset ${fileNameSize}`);

        const file = await UploadService.readAsset(
            reader,
            fileTypeInfo,
            uploadAsset
        );

        if (file.hasStaticThumbnail) {
            metadata.hasStaticThumbnail = true;
        }
        const fileWithMetadata = {
            localID,
            filedata: file.filedata,
            thumbnail: file.thumbnail,
            metadata,
        };

        if (process.env.NEXT_PUBLIC_SKIP_PUT) {
            await sleep(1000);
            return { fileUploadResult: FileUploadResults.ALREADY_UPLOADED };
        }

        logUploadInfo(`encryptAsset ${fileNameSize}`);
        const encryptedFile = await UploadService.encryptAsset(
            worker,
            fileWithMetadata,
            collection.key
        );

        logUploadInfo(`uploadToBucket ${fileNameSize}`);

        const backupedFile: BackupedFile = await UploadService.uploadToBucket(
            encryptedFile.file
        );

        const uploadFile: UploadFile = UploadService.getUploadFile(
            collection,
            backupedFile,
            encryptedFile.fileKey
        );
        logUploadInfo(`uploadFile ${fileNameSize}`);

        const uploadedFile = await UploadHttpClient.uploadFile(uploadFile);
        const decryptedFile = await decryptFile(uploadedFile, collection.key);

        UIService.increaseFileUploaded();
        logUploadInfo(`${fileNameSize} successfully uploaded`);

        return {
            fileUploadResult: FileUploadResults.UPLOADED,
            file: decryptedFile,
        };
    } catch (e) {
        logUploadInfo(
            `upload failed for  ${fileNameSize} ,error: ${e.message}`
        );

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
    }
}
