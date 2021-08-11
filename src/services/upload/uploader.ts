import { File } from 'services/fileService';
import { sleep } from 'utils/common';
import { handleError, CustomError } from 'utils/common/errorUtil';
import { decryptFile } from 'utils/file';
import { logError } from 'utils/sentry';
import { fileAlreadyInCollection } from 'utils/upload';
import NetworkClient from './networkClient';
import uiService from './uiService';
import UploadService, {
    BackupedFile,
    EncryptedFile,
    FileInMemory,
    FileUploadResults,
    FileWithCollection,
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
    fileWithCollection: FileWithCollection,
    existingFilesCollectionWise: Map<number, File[]>,
): Promise<UploadResponse> {
    const { file: rawFile, collection } = fileWithCollection;
    uiService.setFileProgress(rawFile.name, 0);
    let file: FileInMemory = null;
    let encryptedFile: EncryptedFile = null;
    try {
        file = await UploadService.readFile(reader, rawFile);

        if (
            fileAlreadyInCollection(
                existingFilesCollectionWise,
                file,
                collection,
            )
        ) {
            // set progress to -2 indicating that file upload was skipped
            uiService.setFileProgress(rawFile.name, FileUploadResults.SKIPPED);
            await sleep(TwoSecondInMillSeconds);
            return { fileUploadResult: FileUploadResults.SKIPPED };
        }

        encryptedFile = await UploadService.encryptFile(
            worker,
            file,
            collection.key,
        );

        const backupedFile: BackupedFile = await UploadService.uploadToBucket(
            encryptedFile.file,
        );

        const uploadFile: UploadFile = UploadService.getUploadFile(
            collection,
            backupedFile,
            encryptedFile.fileKey,
        );

        const uploadedFile = await NetworkClient.uploadFile(uploadFile);
        const decryptedFile = await decryptFile(uploadedFile, collection);

        uiService.setFileProgress(rawFile.name, FileUploadResults.UPLOADED);
        uiService.increaseFileUploaded();
        return {
            fileUploadResult: FileUploadResults.UPLOADED,
            file: decryptedFile,
        };
    } catch (e) {
        logError(e, 'file upload failed');
        handleError(e);
        if (e.message === CustomError.ETAG_MISSING) {
            uiService.setFileProgress(rawFile.name, FileUploadResults.BLOCKED);
            return { fileUploadResult: FileUploadResults.BLOCKED };
        } else {
            uiService.setFileProgress(rawFile.name, FileUploadResults.FAILED);
            return { fileUploadResult: FileUploadResults.FAILED };
        }
    } finally {
        file = null;
        encryptedFile = null;
    }
}
