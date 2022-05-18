import { NULL_EXTRACTED_METADATA } from 'constants/upload';
import ffmpegService from 'services/ffmpeg/ffmpegService';
import { ElectronFile } from 'types/upload';
import { logError } from 'utils/sentry';
import { logUploadInfo } from 'utils/upload';

export async function getVideoMetadata(file: File | ElectronFile) {
    let videoMetadata = NULL_EXTRACTED_METADATA;
    try {
        if (!(file instanceof File)) {
            logUploadInfo('get file blob for video metadata extraction');
            file = new File([await file.blob()], file.name, {
                lastModified: file.lastModified,
            });
            logUploadInfo(
                'get file blob for video metadata extraction successfully'
            );
        }
        videoMetadata = await ffmpegService.extractMetadata(file);
    } catch (e) {
        logError(e, 'failed to get video metadata');
    }

    return videoMetadata;
}
