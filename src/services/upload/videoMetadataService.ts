import { NULL_EXTRACTED_METADATA } from 'constants/upload';
import ffmpegService from 'services/ffmpeg/ffmpegService';
import { ElectronFile } from 'types/upload';
import { logError } from 'utils/sentry';

export async function getVideoMetadata(file: File | ElectronFile) {
    let videoMetadata = NULL_EXTRACTED_METADATA;
    if (!(file instanceof File)) {
        file = new File([await file.toBlob()], file.name, {
            lastModified: file.lastModified,
            type: file.type.mimeType,
        });
    }
    try {
        videoMetadata = await ffmpegService.extractMetadata(file);
    } catch (e) {
        logError(e, 'failed to get video metadata');
    }

    return videoMetadata;
}
