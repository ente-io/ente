import { NULL_EXTRACTED_METADATA } from 'constants/upload';
import ffmpegService from 'services/ffmpeg/ffmpegService';
import { logError } from 'utils/sentry';

export async function getVideoMetadata(file: File) {
    let videoMetadata = NULL_EXTRACTED_METADATA;
    try {
        videoMetadata = await ffmpegService.extractMetadata(file);
    } catch (e) {
        logError(e, 'failed to get video metadata');
    }

    return videoMetadata;
}
