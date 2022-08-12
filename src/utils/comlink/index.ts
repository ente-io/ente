import * as Comlink from 'comlink';
import { runningInBrowser, runningInWorker } from 'utils/common';
import { ElectronCacheStorage } from 'services/electron/cache';

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

export const getMainThreadElectronCacheStorageRemote = () => {
    if (runningInWorker()) {
        // setupResponseComlinkTransferHandler();
        return Comlink.wrap<ElectronCacheStorage>(self);
    }
};

export const FFmpegWorker: any = getDedicatedFFmpegWorker()?.comlink;

// export const setupResponseComlinkTransferHandler = () => {
//     const transferHandler: Comlink.TransferHandler<Response, ArrayBuffer> = {
//         canHandle: (obj: unknown): obj is Response => obj instanceof Response,
//         serialize: (response: Response) => [
//             response.arrayBuffer() as unknown as ArrayBuffer,
//             [],
//         ],
//         deserialize: (arrayBuffer: ArrayBuffer) => new Response(arrayBuffer),
//     };
//     Comlink.transferHandlers.set('RESPONSE', transferHandler);
// };
