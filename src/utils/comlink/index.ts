import * as Comlink from 'comlink';
import { runningInBrowser } from 'utils/common';

export interface ComlinkWorker {
    comlink: any;
    worker: Worker;
}

const getDedicatedFFmpegWorker = (): ComlinkWorker => {
    if (runningInBrowser()) {
        const worker = new Worker(
            new URL('worker/ffmpeg.worker.js', import.meta.url),
            { name: 'ente-ffmpeg-worker' }
        );
        const comlink = Comlink.wrap(worker);
        return { comlink, worker };
    }
};

export const FFmpegWorker: any = getDedicatedFFmpegWorker()?.comlink;
