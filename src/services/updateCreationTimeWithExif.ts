import { SetProgressTracker } from 'components/FixLargeThumbnail';
import {
    changeFileCreationTime,
    updateExistingFilePubMetadata,
} from 'utils/file';
import { logError } from 'utils/sentry';
import localForage from 'utils/storage/localForage';
import downloadManager from './downloadManager';
import { getLocalFiles, File, updatePublicMagicMetadata } from './fileService';
import { getLocalTrash, getTrashedFiles } from './trashService';
import { getExifDataFromURL } from './upload/exifService';

const CREATION_TIME_UPDATED_FILES_TABLE = 'creation-time-updated-file-table';

export async function getCreationTimeUpdatedFiles() {
    return (
        (await localForage.getItem<number[]>(
            CREATION_TIME_UPDATED_FILES_TABLE
        )) ?? []
    );
}

export async function setCreationTimeUpdatedFiles(creationTimeUpdatedFiles) {
    return await localForage.setItem<number[]>(
        CREATION_TIME_UPDATED_FILES_TABLE,
        creationTimeUpdatedFiles
    );
}

export async function getFilesPendingCreationTimeUpdate() {
    const files = await getLocalFiles();
    const trash = await getLocalTrash();
    const trashFiles = getTrashedFiles(trash);
    const allFiles = [...files, ...trashFiles];
    const updateFiles = new Set(await getCreationTimeUpdatedFiles());

    const pendingFiles = allFiles.filter((file) => !updateFiles.has(file.id));
    return pendingFiles;
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
        const updatedFiles = await getCreationTimeUpdatedFiles();
        setProgressTracker({ current: 0, total: filesToBeUpdated.length });
        for (const [index, file] of filesToBeUpdated.entries()) {
            try {
                const fileURL = await downloadManager.getFile(file);
                const exifData = await getExifDataFromURL(fileURL);
                if (exifData?.creationTime) {
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
                    current: index,
                    total: filesToBeUpdated.length,
                });
                updatedFiles.push(file.id);
                setCreationTimeUpdatedFiles(updatedFiles);
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
