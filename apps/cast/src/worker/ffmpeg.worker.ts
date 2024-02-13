import * as Comlink from 'comlink';
import { WasmFFmpeg } from 'services/wasm/ffmpeg';

export class DedicatedFFmpegWorker {
    wasmFFmpeg: WasmFFmpeg;
    constructor() {
        this.wasmFFmpeg = new WasmFFmpeg();
    }

    run(cmd, inputFile, outputFileName, dontTimeout) {
        return this.wasmFFmpeg.run(cmd, inputFile, outputFileName, dontTimeout);
    }
}

Comlink.expose(DedicatedFFmpegWorker, self);
