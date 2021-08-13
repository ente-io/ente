import { Collection } from 'services/collectionService';
import { File } from 'services/fileService';
import { sleep } from 'utils/common';
import { handleError, CustomError } from 'utils/common/errorUtil';
import { decryptFile } from 'utils/file';
import { logError } from 'utils/sentry';
import { fileAlreadyInCollection } from 'utils/upload';
import NetworkClient from './networkClient';
import UIService from './uiService';
import { FileUploadResults } from './uploadManager';
import UploadService, {
    BackupedFile,
    EncryptedFile,
    FileInMemory,
    UploadFile,
} from './uploadService';

const TwoSecondInMillSeconds = 2000;

interface UploadResponse {
    fileUploadResult: FileUploadResults;
    file?: File;
}
export default async function uploader(
    worker: any,
    reader: FileReader,
    existingFilesInCollection: File[],
    rawFile: globalThis.File,
    collection: Collection
): Promise<UploadResponse> {
    UIService.setFileProgress(rawFile.name, 0);
    let file: FileInMemory = null;
    let encryptedFile: EncryptedFile = null;
    try {
        file = await UploadService.readFile(reader, rawFile, collection);

        if (fileAlreadyInCollection(existingFilesInCollection, file)) {
            // set progress to -2 indicating that file upload was skipped
            UIService.setFileProgress(rawFile.name, FileUploadResults.SKIPPED);
            // wait two second before removing the file from the progress in file section
            await sleep(TwoSecondInMillSeconds);
            return { fileUploadResult: FileUploadResults.SKIPPED };
        }

        encryptedFile = await UploadService.encryptFile(
            worker,
            file,
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

        const uploadedFile = await NetworkClient.uploadFile(uploadFile);
        const decryptedFile = await decryptFile(uploadedFile, collection);

        UIService.setFileProgress(rawFile.name, FileUploadResults.UPLOADED);
        UIService.increaseFileUploaded();
        return {
            fileUploadResult: FileUploadResults.UPLOADED,
            file: decryptedFile,
        };
    } catch (e) {
        logError(e, 'file upload failed');
        handleError(e);
        if (e.message === CustomError.ETAG_MISSING) {
            UIService.setFileProgress(rawFile.name, FileUploadResults.BLOCKED);
            return { fileUploadResult: FileUploadResults.BLOCKED };
        } else {
            UIService.setFileProgress(rawFile.name, FileUploadResults.FAILED);
            return { fileUploadResult: FileUploadResults.FAILED };
        }
    } finally {
        file = null;
        encryptedFile = null;
    }
}
