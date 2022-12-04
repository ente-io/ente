import { ComlinkWorker } from 'utils/comlink/comlinkWorker';
import { runningInBrowser } from 'utils/common';
import { DedicatedConvertWorker } from 'worker/convert.worker';
import { DedicatedCryptoWorker } from 'worker/crypto.worker';
import { DedicatedFFmpegWorker } from 'worker/ffmpeg.worker';

const getDedicatedFFmpegWorker = () => {
    if (runningInBrowser()) {
        const cryptoComlinkWorker = new ComlinkWorker<
            typeof DedicatedFFmpegWorker
        >(
            'ente-ffmpeg-worker',
            new Worker(new URL('worker/ffmpeg.worker.ts', import.meta.url))
        );
        return cryptoComlinkWorker;
    }
};

export const FFmpegWorker = getDedicatedFFmpegWorker()?.remote;

export const getDedicatedCryptoWorker = () => {
    if (runningInBrowser()) {
        const cryptoComlinkWorker = new ComlinkWorker<
            typeof DedicatedCryptoWorker
        >(
            'ente-crypto-worker',
            new Worker(new URL('worker/crypto.worker.ts', import.meta.url))
        );
        return cryptoComlinkWorker;
    }
};
export const CryptoWorker = getDedicatedCryptoWorker()?.remote;

export const getDedicatedConvertWorker = () => {
    if (runningInBrowser()) {
        const cryptoComlinkWorker = new ComlinkWorker<
            typeof DedicatedConvertWorker
        >(
            'ente-convert-worker',
            new Worker(new URL('worker/convert.worker.ts', import.meta.url))
        );
        return cryptoComlinkWorker;
    }
};
