import { NULL_EXTRACTED_METADATA } from 'constants/upload';
import * as ffmpegService from 'services/ffmpeg/ffmpegService';
import { ElectronFile } from 'types/upload';
import { logError } from '@ente/shared/sentry';
import { addLogLine } from '@ente/shared/logging';
import { getFileNameSize } from '@ente/shared/logging/web';

export async function getVideoMetadata(file: File | ElectronFile) {
    let videoMetadata = NULL_EXTRACTED_METADATA;
    try {
        addLogLine(`getVideoMetadata called for ${getFileNameSize(file)}`);
        videoMetadata = await ffmpegService.extractVideoMetadata(file);
        addLogLine(
            `videoMetadata successfully extracted ${getFileNameSize(file)}`
        );
    } catch (e) {
        logError(e, 'failed to get video metadata');
        addLogLine(
            `videoMetadata extracted failed ${getFileNameSize(file)} ,${
                e.message
            } `
        );
    }

    return videoMetadata;
}
