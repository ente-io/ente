import * as Comlink from 'comlink';
import FFmpegClient from 'services/ffmpeg/ffmpegClient';

export class DedicatedFFmpegWorker {
    ffmpegClient: FFmpegClient;
    constructor() {
        this.ffmpegClient = new FFmpegClient();
    }
    async generateThumbnail(file: File) {
        return this.ffmpegClient.generateThumbnail(file);
    }
    async extractVideoMetadata(file: File) {
        return this.ffmpegClient.extractVideoMetadata(file);
    }

    async convertToMP4(file: Uint8Array, inputFileName: string) {
        return this.ffmpegClient.convertToMP4(file, inputFileName);
    }
}

Comlink.expose(DedicatedFFmpegWorker, self);
