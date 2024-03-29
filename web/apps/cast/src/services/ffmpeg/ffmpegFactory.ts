import { ElectronFile } from "types/upload";
import ComlinkFFmpegWorker from "utils/comlink/ComlinkFFmpegWorker";

export interface IFFmpeg {
    run: (
        cmd: string[],
        inputFile: File | ElectronFile,
        outputFilename: string,
        dontTimeout?: boolean,
    ) => Promise<File | ElectronFile>;
}

class FFmpegFactory {
    private client: IFFmpeg;
    async getFFmpegClient() {
        if (!this.client) {
            this.client = await ComlinkFFmpegWorker.getInstance();
        }
        return this.client;
    }
}

export default new FFmpegFactory();
