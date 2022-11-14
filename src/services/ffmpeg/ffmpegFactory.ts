import isElectron from 'is-electron';
import { ElectronFFmpeg } from 'services/electron/ffmpeg';
import { WasmFFmpeg } from 'services/wasm/ffmpeg';
import { FFmpegWorker } from 'utils/comlink';

class FFmpegFactory {
    private client: ElectronFFmpeg | WasmFFmpeg;

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
