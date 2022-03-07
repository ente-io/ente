import { CustomError } from 'utils/error';
import { logError } from 'utils/sentry';
import QueueProcessor from 'services/queueProcessor';
import { ParsedExtractedMetadata } from 'types/upload';

import { FFmpegWorker } from 'utils/comlink';

class FFmpegService {
    private ffmpegWorker = null;
    private ffmpegTaskQueue = new QueueProcessor<any>(1);

    async init() {
        this.ffmpegWorker = await new FFmpegWorker();
    }

    async generateThumbnail(file: File): Promise<Uint8Array> {
        if (!this.ffmpegWorker) {
            await this.init();
        }

        const response = this.ffmpegTaskQueue.queueUpRequest(
            async () => await this.ffmpegWorker.generateThumbnail(file)
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

    async extractMetadata(file: File): Promise<ParsedExtractedMetadata> {
        if (!this.ffmpegWorker) {
            await this.init();
        }

        const response = this.ffmpegTaskQueue.queueUpRequest(
            async () => await this.ffmpegWorker.extractVideoMetadata(file)
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

    async convertToMP4(
        file: Uint8Array,
        fileName: string
    ): Promise<Uint8Array> {
        if (!this.ffmpegWorker) {
            await this.init();
        }

        const response = this.ffmpegTaskQueue.queueUpRequest(
            async () => await this.ffmpegWorker.convertToMP4(file, fileName)
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

export default new FFmpegService();
