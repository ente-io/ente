import { createFFmpeg, FFmpeg } from 'ffmpeg-wasm';
import { getUint8ArrayView } from 'services/readerService';
import {
    parseFFmpegExtractedMetadata,
    splitFilenameAndExtension,
} from 'utils/ffmpeg';

class FFmpegClient {
    private ffmpeg: FFmpeg;
    private ready: Promise<void> = null;
    constructor() {
        this.ffmpeg = createFFmpeg({
            corePath: '/js/ffmpeg/ffmpeg-core.js',
            mt: false,
        });

        this.ready = this.init();
    }

    private async init() {
        if (!this.ffmpeg.isLoaded()) {
            await this.ffmpeg.load();
        }
    }

    async generateThumbnail(file: File) {
        await this.ready;
        // eslint-disable-next-line @typescript-eslint/no-unused-vars
        const [_, ext] = splitFilenameAndExtension(file.name);
        const inputFileName = `${Date.now().toString()}-input.${ext}`;
        const thumbFileName = `${Date.now().toString()}-thumb.jpeg`;
        this.ffmpeg.FS(
            'writeFile',
            inputFileName,
            await getUint8ArrayView(file)
        );
        let seekTime = 1.0;
        let thumb = null;
        while (seekTime > 0) {
            try {
                await this.ffmpeg.run(
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
                thumb = this.ffmpeg.FS('readFile', thumbFileName);
                this.ffmpeg.FS('unlink', thumbFileName);
                break;
            } catch (e) {
                seekTime = Number((seekTime / 10).toFixed(3));
            }
        }
        this.ffmpeg.FS('unlink', inputFileName);
        return thumb;
    }

    async extractVideoMetadata(file: File) {
        await this.ready;
        // eslint-disable-next-line @typescript-eslint/no-unused-vars
        const [_, ext] = splitFilenameAndExtension(file.name);
        const inputFileName = `${Date.now().toString()}-input.${ext}`;
        const outFileName = `${Date.now().toString()}-metadata.txt`;
        this.ffmpeg.FS(
            'writeFile',
            inputFileName,
            await getUint8ArrayView(file)
        );
        let metadata = null;

        // https://stackoverflow.com/questions/9464617/retrieving-and-saving-media-metadata-using-ffmpeg
        // -c [short for codex] copy[(stream_specifier)[ffmpeg.org/ffmpeg.html#Stream-specifiers]] => copies all the stream without re-encoding
        // -map_metadata [http://ffmpeg.org/ffmpeg.html#Advanced-options search for map_metadata] => copies all stream metadata to the out
        // -f ffmetadata [https://ffmpeg.org/ffmpeg-formats.html#Metadata-1] => dump metadata from media files into a simple UTF-8-encoded INI-like text file
        await this.ffmpeg.run(
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
        metadata = this.ffmpeg.FS('readFile', outFileName);
        this.ffmpeg.FS('unlink', outFileName);
        this.ffmpeg.FS('unlink', inputFileName);
        return parseFFmpegExtractedMetadata(metadata);
    }

    async convertToMP4(file: Uint8Array, inputFileName: string) {
        await this.ready;
        this.ffmpeg.FS('writeFile', inputFileName, file);
        await this.ffmpeg.run(
            '-i',
            inputFileName,
            '-preset',
            'ultrafast',
            'output.mp4'
        );
        const convertedFile = this.ffmpeg.FS('readFile', 'output.mp4');
        this.ffmpeg.FS('unlink', inputFileName);
        this.ffmpeg.FS('unlink', 'output.mp4');
        return convertedFile;
    }
}

export default FFmpegClient;
