import * as Comlink from 'comlink';
import WasmFFmpeg from 'services/wasm/ffmpeg';

export class FFmpeg {
    wasmFFmpeg;
    constructor() {
        this.wasmFFmpeg = new WasmFFmpeg();
    }

    run(cmd, inputFile, outputFileName) {
        return this.wasmFFmpeg.run(cmd, inputFile, outputFileName);
    }
}

Comlink.expose(FFmpeg);
