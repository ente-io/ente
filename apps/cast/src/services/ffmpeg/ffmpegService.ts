import {
    FFMPEG_PLACEHOLDER,
    INPUT_PATH_PLACEHOLDER,
    OUTPUT_PATH_PLACEHOLDER,
} from 'constants/ffmpeg';
import { ElectronFile } from 'types/upload';
import ffmpegFactory from './ffmpegFactory';
import { logError } from '@ente/shared/sentry';

export async function convertToMP4(file: File | ElectronFile) {
    try {
        const ffmpegClient = await ffmpegFactory.getFFmpegClient();
        return await ffmpegClient.run(
            [
                FFMPEG_PLACEHOLDER,
                '-i',
                INPUT_PATH_PLACEHOLDER,
                '-preset',
                'ultrafast',
                OUTPUT_PATH_PLACEHOLDER,
            ],
            file,
            'output.mp4',
            true
        );
    } catch (e) {
        logError(e, 'ffmpeg convertToMP4 failed');
        throw e;
    }
}
