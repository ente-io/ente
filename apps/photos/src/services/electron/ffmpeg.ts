import { IFFmpeg } from 'services/ffmpeg/ffmpegFactory';
import { ElectronAPIs } from 'types/electron';
import { ElectronFile } from 'types/upload';

export class ElectronFFmpeg implements IFFmpeg {
    private electronAPIs: ElectronAPIs;

    constructor() {
        this.electronAPIs = globalThis['ElectronAPIs'];
    }

    async run(
        cmd: string[],
        inputFile: ElectronFile | File,
        outputFilename: string,
        dontTimeout?: boolean
    ) {
        if (this.electronAPIs?.runFFmpegCmd) {
            return this.electronAPIs.runFFmpegCmd(
                cmd,
                inputFile,
                outputFilename,
                dontTimeout
            );
        }
    }
}
