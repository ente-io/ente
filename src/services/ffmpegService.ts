import { createFFmpeg, FFmpeg } from '@ffmpeg/ffmpeg';
import { CustomError } from 'utils/error';
import { logError } from 'utils/sentry';
import QueueProcessor from './queueProcessor';
import { getUint8ArrayView } from './upload/readFileService';

class FFmpegService {
    private ffmpeg: FFmpeg = null;
    private isLoading = null;
    private fileReader: FileReader = null;

    private ffmpegTaskQueue = new QueueProcessor<Uint8Array>(1);
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

    async generateThumbnail(file: File) {
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

    async convertToMP4(
        file: Uint8Array,
        fileName: string
    ): Promise<Uint8Array> {
        if (!this.ffmpeg) {
            await this.init();
        }
        if (this.isLoading) {
            await this.isLoading;
        }

        const response = this.ffmpegTaskQueue.queueUpRequest(
            convertToMP4Helper.bind(null, this.ffmpeg, file, fileName)
        );

        try {
            return await response.promise;
        } catch (e) {
            if (e.message === CustomError.REQUEST_CANCELLED) {
                // ignore
                return null;
            } else {
                logError(e, 'ffmpeg MP4 conversion failed');
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

async function convertToMP4Helper(
    ffmpeg: FFmpeg,
    file: Uint8Array,
    inputFileName: string
) {
    try {
        ffmpeg.FS('writeFile', inputFileName, file);
        await ffmpeg.run(
            '-i',
            inputFileName,
            '-preset',
            'ultrafast',
            'output.mp4'
        );
        const convertedFile = ffmpeg.FS('readFile', 'output.mp4');
        ffmpeg.FS('unlink', inputFileName);
        ffmpeg.FS('unlink', 'output.mp4');
        return convertedFile;
    } catch (e) {
        logError(e, 'ffmpeg MP4 conversion failed');
        throw e;
    }
}

export default new FFmpegService();
