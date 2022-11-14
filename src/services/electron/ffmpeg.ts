import { IFFmpeg } from 'services/ffmpeg/ffmpegFactory';
import { ElectronAPIs } from 'types/electron';
import { ElectronFile } from 'types/upload';
import { runningInBrowser } from 'utils/common';

export class ElectronFFmpeg implements IFFmpeg {
    private electronAPIs: ElectronAPIs;

    constructor() {
        this.electronAPIs = runningInBrowser() && globalThis['ElectronAPIs'];
    }

    async run(cmd: string[], inputFile: ElectronFile, outputFilename: string) {
        if (this.electronAPIs?.runFFmpegCmd) {
            return this.electronAPIs.runFFmpegCmd(
                cmd,
                inputFile,
                outputFilename
            );
        }
    }
}
