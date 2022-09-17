import * as Comlink from 'comlink';
import { ComlinkWorker } from 'utils/comlink/comlinkWorker';
import { runningInBrowser } from 'utils/common';
import { DedicatedConvertWorker } from 'worker/convert.worker';
import { DedicatedCryptoWorker } from 'worker/crypto.worker';

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

export const getDedicatedCryptoWorker = () => {
    if (runningInBrowser()) {
        const cryptoComlinkWorker = new ComlinkWorker<
            typeof DedicatedCryptoWorker
        >('ente-crypto-worker', 'worker/crypto.worker.ts');
        return cryptoComlinkWorker;
    }
};
export const CryptoWorker = getDedicatedCryptoWorker()?.remote;

export const getDedicatedConvertWorker = () => {
    if (runningInBrowser()) {
        const cryptoComlinkWorker = new ComlinkWorker<
            typeof DedicatedConvertWorker
        >('ente-convert-worker', 'worker/convert.worker.ts');
        return cryptoComlinkWorker;
    }
};
