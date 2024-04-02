import ComlinkFFmpegWorker from "utils/comlink/ComlinkFFmpegWorker";

export interface IFFmpeg {
    run: (
        cmd: string[],
        inputFile: File,
        outputFilename: string,
        dontTimeout?: boolean,
    ) => Promise<File>;
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
