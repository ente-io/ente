import { SetProgressTracker } from 'components/FixLargeThumbnail';
import CryptoWorker from 'utils/crypto';
import {
    changeFileCreationTime,
    getFileFromURL,
    updateExistingFilePubMetadata,
} from 'utils/file';
import { logError } from 'utils/sentry';
import localForage from 'utils/storage/localForage';
import downloadManager from './downloadManager';
import { File, updatePublicMagicMetadata } from './fileService';
import { getExifData } from './upload/exifService';
import { getFileType } from './upload/readFileService';

const CREATION_TIME_UPDATED_FILES_TABLE = 'creation-time-updated-file-table';

export async function setCreationTimeUpdatedFiles(creationTimeUpdatedFiles) {
    return await localForage.setItem<number[]>(
        CREATION_TIME_UPDATED_FILES_TABLE,
        creationTimeUpdatedFiles
    );
}

export async function updateCreationTimeWithExif(
    filesToBeUpdated: File[],
    setProgressTracker: SetProgressTracker
) {
    let completedWithError = false;
    try {
        if (filesToBeUpdated.length === 0) {
            return completedWithError;
        }
        setProgressTracker({ current: 0, total: filesToBeUpdated.length });
        for (const [index, file] of filesToBeUpdated.entries()) {
            try {
                const fileURL = await downloadManager.getFile(file);
                const fileObject = await getFileFromURL(fileURL);
                const worker = await new CryptoWorker();
                const fileTypeInfo = await getFileType(worker, fileObject);
                const exifData = await getExifData(fileObject, fileTypeInfo);
                if (
                    exifData?.creationTime &&
                    exifData?.creationTime !== file.metadata.creationTime
                ) {
                    let updatedFile = await changeFileCreationTime(
                        file,
                        exifData.creationTime
                    );
                    updatedFile = (
                        await updatePublicMagicMetadata([updatedFile])
                    )[0];
                    updateExistingFilePubMetadata(file, updatedFile);
                }
                setProgressTracker({
                    current: index + 1,
                    total: filesToBeUpdated.length,
                });
            } catch (e) {
                logError(e, 'failed to updated a CreationTime With Exif');
                completedWithError = true;
            }
        }
    } catch (e) {
        logError(e, 'update CreationTime With Exif failed');
        completedWithError = true;
    }
    return completedWithError;
}
