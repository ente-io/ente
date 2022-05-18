import { EnteFile } from 'types/file';
import { handleUploadError, CustomError } from 'utils/error';
import { logError } from 'utils/sentry';
import {
    fileAlreadyInCollection,
    shouldDedupeAcrossCollection,
} from 'utils/upload';
import UploadHttpClient from './uploadHttpClient';
import UIService from './uiService';
import UploadService from './uploadService';
import { FILE_TYPE } from 'constants/file';
import { FileUploadResults } from 'constants/upload';
import { FileWithCollection, BackupedFile, UploadFile } from 'types/upload';
import { logUploadInfo } from 'utils/upload';
import { convertBytesToHumanReadable } from 'utils/billing';
import { sleep } from 'utils/common';

interface UploadResponse {
    fileUploadResult: FileUploadResults;
    uploadedFile?: EnteFile;
}
export default async function uploader(
    worker: any,
    reader: FileReader,
    existingFilesInCollection: EnteFile[],
    existingFiles: EnteFile[],
    fileWithCollection: FileWithCollection
): Promise<UploadResponse> {
    const { collection, localID, ...uploadAsset } = fileWithCollection;
    const fileNameSize = `${UploadService.getAssetName(
        fileWithCollection
    )}_${convertBytesToHumanReadable(UploadService.getAssetSize(uploadAsset))}`;

    logUploadInfo(`uploader called for  ${fileNameSize}`);
    UIService.setFileProgress(localID, 0);
    await sleep(0);
    const { fileTypeInfo, metadata } =
        UploadService.getFileMetadataAndFileTypeInfo(localID);
    try {
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

        // iOS exports via album doesn't export files without collection and if user exports all photos, album info is not preserved.
        // This change allow users to export by albums, upload to ente. And export all photos -> upload files which are not already uploaded
        // as part of the albums
        if (
            shouldDedupeAcrossCollection(fileWithCollection.collection.name) &&
            fileAlreadyInCollection(existingFiles, metadata)
        ) {
            logUploadInfo(`deduped upload for  ${fileNameSize}`);
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

        UIService.increaseFileUploaded();
        logUploadInfo(`${fileNameSize} successfully uploaded`);

        return {
            fileUploadResult: metadata.hasStaticThumbnail
                ? FileUploadResults.UPLOADED_WITH_BLACK_THUMBNAIL
                : FileUploadResults.UPLOADED,
            uploadedFile: uploadedFile,
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
