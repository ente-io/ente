import { FIX_OPTIONS } from 'components/FixCreationTime';
import { SetProgressTracker } from 'components/FixLargeThumbnail';
import {
    changeFileCreationTime,
    getFileFromURL,
    updateExistingFilePubMetadata,
} from 'utils/file';
import { logError } from 'utils/sentry';
import downloadManager from './downloadManager';
import { updateFilePublicMagicMetadata } from './fileService';
import { EnteFile } from 'types/file';

import { getRawExif } from './upload/exifService';
import { getFileType } from 'services/typeDetectionService';
import { FILE_TYPE } from 'constants/file';
import { getUnixTimeInMicroSeconds } from 'utils/time';

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
                    correctCreationTime = getUnixTimeInMicroSeconds(customTime);
                } else {
                    const fileURL = await downloadManager.getFile(file)[0];
                    const fileObject = await getFileFromURL(fileURL);
                    const fileTypeInfo = await getFileType(fileObject);
                    const exifData = await getRawExif(fileObject, fileTypeInfo);
                    if (fixOption === FIX_OPTIONS.DATE_TIME_ORIGINAL) {
                        correctCreationTime = getUnixTimeInMicroSeconds(
                            exifData?.DateTimeOriginal
                        );
                    } else {
                        correctCreationTime = getUnixTimeInMicroSeconds(
                            exifData?.CreateDate
                        );
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
                        await updateFilePublicMagicMetadata([updatedFile])
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
