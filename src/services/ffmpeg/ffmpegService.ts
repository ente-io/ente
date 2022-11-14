import {
    INPUT_PATH_PLACEHOLDER,
    OUTPUT_PATH_PLACEHOLDER,
} from 'constants/ffmpeg';
import { ElectronFile } from 'types/upload';
import ffmpegFactory from './ffmpegFactory';

export async function generateThumbnail(file: File | ElectronFile) {
    let seekTime = 1.0;
    const thumb = null;
    const ffmpegClient = await ffmpegFactory.getFFmpegClient();
    while (seekTime > 0) {
        try {
            return await ffmpegClient.run(
                [
                    '-i',
                    INPUT_PATH_PLACEHOLDER,
                    '-ss',
                    `00:00:0${seekTime.toFixed(3)}`,
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
            seekTime = Number((seekTime / 10).toFixed(3));
        }
    }
    return thumb;
}

//     async extractVideoMetadata(file: File) {
//         await this.ready;
//         // eslint-disable-next-line @typescript-eslint/no-unused-vars
//         const [_, ext] = splitFilenameAndExtension(file.name);
//         const inputFileName = `${Date.now().toString()}-input.${ext}`;
//         const outFileName = `${Date.now().toString()}-metadata.txt`;
//         this.ffmpeg.FS(
//             'writeFile',
//             inputFileName,
//             await getUint8ArrayView(file)
//         );
//         let metadata = null;

//         // https://stackoverflow.com/questions/9464617/retrieving-and-saving-media-metadata-using-ffmpeg
//         // -c [short for codex] copy[(stream_specifier)[ffmpeg.org/ffmpeg.html#Stream-specifiers]] => copies all the stream without re-encoding
//         // -map_metadata [http://ffmpeg.org/ffmpeg.html#Advanced-options search for map_metadata] => copies all stream metadata to the out
//         // -f ffmetadata [https://ffmpeg.org/ffmpeg-formats.html#Metadata-1] => dump metadata from media files into a simple UTF-8-encoded INI-like text file
//         await this.ffmpeg.run(
//             '-i',
//             inputFileName,
//             '-c',
//             'copy',
//             '-map_metadata',
//             '0',
//             '-f',
//             'ffmetadata',
//             outFileName
//         );
//         metadata = this.ffmpeg.FS('readFile', outFileName);
//         this.ffmpeg.FS('unlink', outFileName);
//         this.ffmpeg.FS('unlink', inputFileName);
//         return parseFFmpegExtractedMetadata(metadata);
//     }

//     async convertToMP4(file: Uint8Array, inputFileName: string) {
//         await this.ready;
//         this.ffmpeg.FS('writeFile', inputFileName, file);
//         await this.ffmpeg.run(
//             '-i',
//             inputFileName,
//             '-preset',
//             'ultrafast',
//             'output.mp4'
//         );
//         const convertedFile = this.ffmpeg.FS('readFile', 'output.mp4');
//         this.ffmpeg.FS('unlink', inputFileName);
//         this.ffmpeg.FS('unlink', 'output.mp4');
//         return convertedFile;
//     }
