import {
    FFMPEG_PLACEHOLDER,
    INPUT_PATH_PLACEHOLDER,
    OUTPUT_PATH_PLACEHOLDER,
} from 'constants/ffmpeg';
import { ElectronFile } from 'types/upload';
import { parseFFmpegExtractedMetadata } from 'utils/ffmpeg';
import { logError } from 'utils/sentry';
import ffmpegFactory from './ffmpegFactory';

export async function generateVideoThumbnail(
    file: File | ElectronFile
): Promise<File | ElectronFile> {
    try {
        let seekTime = 1;
        const ffmpegClient = await ffmpegFactory.getFFmpegClient();
        while (seekTime >= 0) {
            try {
                return await ffmpegClient.run(
                    [
                        FFMPEG_PLACEHOLDER,
                        '-i',
                        INPUT_PATH_PLACEHOLDER,
                        '-ss',
                        `00:00:0${seekTime}`,
                        '-vframes',
                        '1',
                        '-vf',
                        'scale=-1:720',
                        OUTPUT_PATH_PLACEHOLDER,
                    ],
                    file,
                    'thumb.jpeg'
                );
            } catch (e) {
                if (seekTime === 0) {
                    throw e;
                }
            }
            seekTime--;
        }
    } catch (e) {
        logError(e, 'ffmpeg generateVideoThumbnail failed');
        throw e;
    }
}

export async function extractVideoMetadata(file: File | ElectronFile) {
    try {
        const ffmpegClient = await ffmpegFactory.getFFmpegClient();
        // https://stackoverflow.com/questions/9464617/retrieving-and-saving-media-metadata-using-ffmpeg
        // -c [short for codex] copy[(stream_specifier)[ffmpeg.org/ffmpeg.html#Stream-specifiers]] => copies all the stream without re-encoding
        // -map_metadata [http://ffmpeg.org/ffmpeg.html#Advanced-options search for map_metadata] => copies all stream metadata to the out
        // -f ffmetadata [https://ffmpeg.org/ffmpeg-formats.html#Metadata-1] => dump metadata from media files into a simple UTF-8-encoded INI-like text file
        const metadata = await ffmpegClient.run(
            [
                FFMPEG_PLACEHOLDER,
                '-i',
                INPUT_PATH_PLACEHOLDER,
                '-c',
                'copy',
                '-map_metadata',
                '0',
                '-f',
                'ffmetadata',
                OUTPUT_PATH_PLACEHOLDER,
            ],
            file,
            `metadata.txt`
        );
        return parseFFmpegExtractedMetadata(
            new Uint8Array(await metadata.arrayBuffer())
        );
    } catch (e) {
        logError(e, 'ffmpeg extractVideoMetadata failed');
        throw e;
    }
}

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
