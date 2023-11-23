import ElectronAPIs from '@ente/shared/electron';
import isElectron from 'is-electron';
import { ElectronFile } from 'types/upload';
import ComlinkFFmpegWorker from 'utils/comlink/ComlinkFFmpegWorker';

export interface IFFmpeg {
    run: (
        cmd: string[],
        inputFile: File | ElectronFile,
        outputFilename: string,
        dontTimeout?: boolean
    ) => Promise<File | ElectronFile>;
}

class FFmpegFactory {
    private client: IFFmpeg;
    async getFFmpegClient() {
        if (!this.client) {
            if (isElectron()) {
                this.client = {
                    run(cmd, inputFile, outputFilename, dontTimeout) {
                        return ElectronAPIs.runFFmpegCmd(
                            cmd,
                            inputFile,
                            outputFilename,
                            dontTimeout
                        );
                    },
                };
            } else {
                this.client = await ComlinkFFmpegWorker.getInstance();
            }
        }
        return this.client;
    }
}

export default new FFmpegFactory();
