import { createFFmpeg, FFmpeg } from '@ffmpeg/ffmpeg';
import { getUint8ArrayView } from './upload/readFileService';

class FFmpegService {
    private ffmpeg: FFmpeg = null;
    async init() {
        try {
            this.ffmpeg = createFFmpeg({
                log: true,
                corePath: '/js/ffmpeg-core.js',
            });
            console.log('Loading ffmpeg-core.js');
            await this.ffmpeg.load();
        } catch (e) {
            throw Error('ffmpeg load failed');
        }
    }

    async generateThumbnail(file: File) {
        if (!this.ffmpeg) {
            await this.init();
        }
        this.ffmpeg.FS(
            'writeFile',
            file.name,
            await getUint8ArrayView(new FileReader(), file)
        );

        await this.ffmpeg.run(
            '-i',
            file.name,
            '-ss',
            '00:00:01.000',
            '-vframes',
            '1',
            'thumb.png'
        );
        console.log('Complete transcoding');
        const thumb = this.ffmpeg.FS('readFile', 'thumb.png');
        return thumb;
    }
}

export default new FFmpegService();
