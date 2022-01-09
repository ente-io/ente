import { FIX_OPTIONS } from 'components/FixCreationTime';
import { SetProgressTracker } from 'components/FixLargeThumbnail';
import {
    changeFileCreationTime,
    getFileFromURL,
    updateExistingFilePubMetadata,
} from 'utils/file';
import { logError } from 'utils/sentry';
import downloadManager from './downloadManager';
import { updatePublicMagicMetadata } from './fileService';
import { EnteFile } from 'types/file';

import { getRawExif, getUNIXTime } from './upload/exifService';
import { getFileType } from './upload/readFileService';
import { FILE_TYPE } from 'constants/file';

export async function updateCreationTimeWithExif(
    filesToBeUpdated: EnteFile[],
    fixOption: FIX_OPTIONS,
    customTime: Date,
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
                if (file.metadata.fileType !== FILE_TYPE.IMAGE) {
                    continue;
                }
                let correctCreationTime: number;
                if (fixOption === FIX_OPTIONS.CUSTOM_TIME) {
                    correctCreationTime = getUNIXTime(customTime);
                } else {
                    const fileURL = await downloadManager.getFile(file);
                    const fileObject = await getFileFromURL(fileURL);
                    const reader = new FileReader();
                    const fileTypeInfo = await getFileType(reader, fileObject);
                    const exifData = await getRawExif(fileObject, fileTypeInfo);
                    if (fixOption === FIX_OPTIONS.DATE_TIME_ORIGINAL) {
                        correctCreationTime = getUNIXTime(
                            exifData?.DateTimeOriginal
                        );
                    } else {
                        correctCreationTime = getUNIXTime(exifData?.CreateDate);
                    }
                }
                if (
                    correctCreationTime &&
                    correctCreationTime !== file.metadata.creationTime
                ) {
                    let updatedFile = await changeFileCreationTime(
                        file,
                        correctCreationTime
                    );
                    updatedFile = (
                        await updatePublicMagicMetadata([updatedFile])
                    )[0];
                    updateExistingFilePubMetadata(file, updatedFile);
                }
            } catch (e) {
                logError(e, 'failed to updated a CreationTime With Exif');
                completedWithError = true;
            } finally {
                setProgressTracker({
                    current: index + 1,
                    total: filesToBeUpdated.length,
                });
            }
        }
    } catch (e) {
        logError(e, 'update CreationTime With Exif failed');
        completedWithError = true;
    }
    return completedWithError;
}
