import { createFFmpeg, FFmpeg } from '@ffmpeg/ffmpeg';
import { CustomError } from 'utils/error';
import { logError } from 'utils/sentry';
import QueueProcessor from './queueProcessor';
import {
    ParsedVideoMetadata,
    parseFFmpegExtractedMetadata,
} from './upload/metadataService';
import { getUint8ArrayView } from './upload/readFileService';

class FFmpegService {
    private ffmpeg: FFmpeg = null;
    private isLoading = null;
    private fileReader: FileReader = null;

    private ffmpegTaskQueue = new QueueProcessor<any>(1);
    async init() {
        try {
            this.ffmpeg = createFFmpeg({
                corePath: '/js/ffmpeg/ffmpeg-core.js',
            });
            this.isLoading = this.ffmpeg.load();
            await this.isLoading;
            this.isLoading = null;
        } catch (e) {
            logError(e, 'ffmpeg load failed');
            this.ffmpeg = null;
            this.isLoading = null;
            throw e;
        }
    }

    async generateThumbnail(file: File): Promise<Uint8Array> {
        if (!this.ffmpeg) {
            await this.init();
        }
        if (!this.fileReader) {
            this.fileReader = new FileReader();
        }
        if (this.isLoading) {
            await this.isLoading;
        }
        const response = this.ffmpegTaskQueue.queueUpRequest(
            generateThumbnailHelper.bind(
                null,
                this.ffmpeg,
                this.fileReader,
                file
            )
        );
        try {
            return await response.promise;
        } catch (e) {
            if (e.message === CustomError.REQUEST_CANCELLED) {
                // ignore
                return null;
            } else {
                logError(e, 'ffmpeg thumbnail generation failed');
                throw e;
            }
        }
    }

    async extractMetadata(file: File): Promise<ParsedVideoMetadata> {
        if (!this.ffmpeg) {
            await this.init();
        }
        if (!this.fileReader) {
            this.fileReader = new FileReader();
        }
        if (this.isLoading) {
            await this.isLoading;
        }
        const response = this.ffmpegTaskQueue.queueUpRequest(
            extractVideoMetadataHelper.bind(
                null,
                this.ffmpeg,
                this.fileReader,
                file
            )
        );
        try {
            return await response.promise;
        } catch (e) {
            if (e.message === CustomError.REQUEST_CANCELLED) {
                // ignore
                return null;
            } else {
                logError(e, 'ffmpeg metadata extraction failed');
                throw e;
            }
        }
    }
}

async function generateThumbnailHelper(
    ffmpeg: FFmpeg,
    reader: FileReader,
    file: File
) {
    try {
        const inputFileName = `${Date.now().toString()}-${file.name}`;
        const thumbFileName = `${Date.now().toString()}-thumb.jpeg`;
        ffmpeg.FS(
            'writeFile',
            inputFileName,
            await getUint8ArrayView(reader, file)
        );
        let seekTime = 1.0;
        let thumb = null;
        while (seekTime > 0) {
            try {
                await ffmpeg.run(
                    '-i',
                    inputFileName,
                    '-ss',
                    `00:00:0${seekTime.toFixed(3)}`,
                    '-vframes',
                    '1',
                    '-vf',
                    'scale=-1:720',
                    thumbFileName
                );
                thumb = ffmpeg.FS('readFile', thumbFileName);
                ffmpeg.FS('unlink', thumbFileName);
                break;
            } catch (e) {
                seekTime = Number((seekTime / 10).toFixed(3));
            }
        }
        ffmpeg.FS('unlink', inputFileName);
        return thumb;
    } catch (e) {
        logError(e, 'ffmpeg thumbnail generation failed');
        throw e;
    }
}

async function extractVideoMetadataHelper(
    ffmpeg: FFmpeg,
    reader: FileReader,
    file: File
) {
    try {
        const inputFileName = `${Date.now().toString()}-${file.name}`;
        const outFileName = `${Date.now().toString()}-metadata.txt`;
        ffmpeg.FS(
            'writeFile',
            inputFileName,
            await getUint8ArrayView(reader, file)
        );
        let metadata = null;

        // https://stackoverflow.com/questions/9464617/retrieving-and-saving-media-metadata-using-ffmpeg
        // -c [short for codex] copy[(stream_specifier)[ffmpeg.org/ffmpeg.html#Stream-specifiers]] => copies all the stream without re-encoding
        // -map_metadata [http://ffmpeg.org/ffmpeg.html#Advanced-options search for map_metadata] => copies all stream metadata to the out
        // -f ffmetadata [https://ffmpeg.org/ffmpeg-formats.html#Metadata-1] => dump metadata from media files into a simple UTF-8-encoded INI-like text file
        await ffmpeg.run(
            '-i',
            inputFileName,
            '-c',
            'copy',
            '-map_metadata',
            '0',
            '-f',
            'ffmetadata',
            outFileName
        );
        metadata = ffmpeg.FS('readFile', outFileName);
        ffmpeg.FS('unlink', outFileName);
        ffmpeg.FS('unlink', inputFileName);
        return parseFFmpegExtractedMetadata(metadata);
    } catch (e) {
        logError(e, 'ffmpeg metadata extraction failed');
        throw e;
    }
}

export default new FFmpegService();
