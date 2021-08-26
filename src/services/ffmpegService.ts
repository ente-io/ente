import { createFFmpeg, FFmpeg } from '@ffmpeg/ffmpeg';
import QueueProcessor from './upload/queueProcessor';
import { getUint8ArrayView } from './upload/readFileService';

class FFmpegService {
    private ffmpeg: FFmpeg = null;
    private isLoading = null;

    private generateThumbnailProcessor = new QueueProcessor<Uint8Array>(1);
    async init() {
        try {
            this.ffmpeg = createFFmpeg({
                log: true,
                corePath: '/js/ffmpeg-core.js',
            });
            console.log('Loading ffmpeg-core.js');
            this.isLoading = this.ffmpeg.load();
            await this.isLoading;
            this.isLoading = null;
            console.log('ffmpeg loaded');
        } catch (e) {
            throw Error('ffmpeg load failed');
        }
    }

    async generateThumbnail(file: File) {
        if (!this.ffmpeg) {
            await this.init();
        }
        if (this.isLoading) {
            await this.isLoading;
        }
        const response = this.generateThumbnailProcessor.queueUpRequest(
            generateThumbnailHelper.bind(null, this.ffmpeg, file)
        );

        const thumbnail = await response.promise;
        return thumbnail;
    }
}

async function generateThumbnailHelper(ffmpeg: FFmpeg, file: File) {
    ffmpeg.FS(
        'writeFile',
        file.name,
        await getUint8ArrayView(new FileReader(), file)
    );

    await ffmpeg.run(
        '-i',
        file.name,
        '-ss',
        '00:00:01.000',
        '-vframes',
        '1',
        'thumb.png'
    );
    console.log('Complete transcoding');
    const thumb = ffmpeg.FS('readFile', 'thumb.png');
    return thumb;
}

export default new FFmpegService();
