import { Remote } from 'comlink';
import { DedicatedFFmpegWorker } from 'worker/ffmpeg.worker';
import { ComlinkWorker } from '@ente/shared/worker/comlinkWorker';

class ComlinkFFmpegWorker {
    private comlinkWorkerInstance: Promise<Remote<DedicatedFFmpegWorker>>;

    async getInstance() {
        if (!this.comlinkWorkerInstance) {
            const comlinkWorker = getDedicatedFFmpegWorker();
            this.comlinkWorkerInstance = comlinkWorker.remote;
        }
        return this.comlinkWorkerInstance;
    }
}

const getDedicatedFFmpegWorker = () => {
    const cryptoComlinkWorker = new ComlinkWorker<typeof DedicatedFFmpegWorker>(
        'ente-ffmpeg-worker',
        new Worker(new URL('worker/ffmpeg.worker.ts', import.meta.url))
    );
    return cryptoComlinkWorker;
};

export default new ComlinkFFmpegWorker();
