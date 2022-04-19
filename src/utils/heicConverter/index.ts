import { ComlinkWorker } from 'utils/comlink';
import { runningInBrowser } from 'utils/common';
import * as Comlink from 'comlink';

const getDedicatedConvertWorker = (): ComlinkWorker => {
    if (runningInBrowser()) {
        const worker = new Worker(
            new URL('worker/convert.worker.js', import.meta.url),
            { name: 'ente-convert-worker' }
        );
        const comlink = Comlink.wrap(worker);
        return { comlink, worker };
    }
};

export const createNewConvertWorker = async () => {
    const comlinkWrapperWorker = getDedicatedConvertWorker();
    if (comlinkWrapperWorker) {
        return {
            comlink: await new comlinkWrapperWorker.comlink(),
            worker: comlinkWrapperWorker.worker,
        };
    }
};
