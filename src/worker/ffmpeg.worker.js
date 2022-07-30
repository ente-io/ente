import * as Comlink from 'comlink';
import FFmpegClient from 'services/ffmpeg/ffmpegClient';

export class FFmpeg {
    ffmpegClient;
    constructor() {
        this.ffmpegClient = new FFmpegClient();
    }
    async generateThumbnail(file) {
        return this.ffmpegClient.generateThumbnail(file);
    }
    async extractVideoMetadata(file) {
        return this.ffmpegClient.extractVideoMetadata(file);
    }

    async convertToMP4(file, inputFileName) {
        return this.ffmpegClient.convertToMP4(file, inputFileName);
    }
}

Comlink.expose(FFmpeg);
