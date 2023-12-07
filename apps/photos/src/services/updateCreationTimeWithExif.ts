import { FIX_OPTIONS } from 'components/FixCreationTime';
import { SetProgressTracker } from 'components/FixLargeThumbnail';
import {
    changeFileCreationTime,
    updateExistingFilePubMetadata,
} from 'utils/file';
import { logError } from '@ente/shared/sentry';
import downloadManager from './download';
import { EnteFile } from 'types/file';

import { getParsedExifData } from './upload/exifService';
import { getFileType } from 'services/typeDetectionService';
import { FILE_TYPE } from 'constants/file';
import { validateAndGetCreationUnixTimeInMicroSeconds } from '@ente/shared/time';

const EXIF_TIME_TAGS = [
    'DateTimeOriginal',
    'CreateDate',
    'ModifyDate',
    'DateCreated',
    'MetadataDate',
];

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
                let correctCreationTime: number;
                if (fixOption === FIX_OPTIONS.CUSTOM_TIME) {
                    correctCreationTime = customTime.getTime() * 1000;
                } else {
                    if (file.metadata.fileType !== FILE_TYPE.IMAGE) {
                        continue;
                    }
                    const fileStream = await downloadManager.getFile(file);
                    const fileBlob = await new Response(fileStream).blob();
                    const fileObject = new File(
                        [fileBlob],
                        file.metadata.title
                    );
                    const fileTypeInfo = await getFileType(fileObject);
                    const exifData = await getParsedExifData(
                        fileObject,
                        fileTypeInfo,
                        EXIF_TIME_TAGS
                    );
                    if (fixOption === FIX_OPTIONS.DATE_TIME_ORIGINAL) {
                        correctCreationTime =
                            validateAndGetCreationUnixTimeInMicroSeconds(
                                exifData?.DateTimeOriginal ??
                                    exifData?.DateCreated
                            );
                    } else if (fixOption === FIX_OPTIONS.DATE_TIME_DIGITIZED) {
                        correctCreationTime =
                            validateAndGetCreationUnixTimeInMicroSeconds(
                                exifData?.CreateDate
                            );
                    } else if (fixOption === FIX_OPTIONS.METADATA_DATE) {
                        correctCreationTime =
                            validateAndGetCreationUnixTimeInMicroSeconds(
                                exifData?.MetadataDate
                            );
                    } else {
                        throw new Error('Invalid fix option');
                    }
                }
                if (
                    correctCreationTime &&
                    correctCreationTime !== file.metadata.creationTime
                ) {
                    const updatedFile = await changeFileCreationTime(
                        file,
                        correctCreationTime
                    );
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
