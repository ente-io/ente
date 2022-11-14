import isElectron from 'is-electron';
import { ElectronFFmpeg } from 'services/electron/ffmpeg';
import { ElectronFile } from 'types/upload';
import { FFmpegWorker } from 'utils/comlink';

export interface IFFmpeg {
    run: (
        cmd: string[],
        inputFile: File | ElectronFile,
        outputFilename: string
    ) => Promise<File | ElectronFile>;
}

class FFmpegFactory {
    private client: IFFmpeg;

    async getFFmpegClient() {
        if (this.client) {
            return this.client;
        }
        if (isElectron()) {
            this.client = new ElectronFFmpeg();
        } else {
            this.client = await new FFmpegWorker();
        }
    }
}
export default new FFmpegFactory();
