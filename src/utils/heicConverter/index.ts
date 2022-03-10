import { ComlinkWorker } from 'utils/comlink';
import { runningInBrowser } from 'utils/common';
import { CustomError } from 'utils/error';
import * as Comlink from 'comlink';

const getDedicatedConvertWorker = (): ComlinkWorker => {
    if (runningInBrowser()) {
        const worker = new Worker(
            new URL('worker/convert.worker.js', import.meta.url),
            { name: 'ente-convert-worker' }
        );
        const comlink = Comlink.wrap(worker);
        return { comlink, worker };
    } else {
        throw Error(CustomError.NOT_A_BROWSER);
    }
};

export const createNewConvertWorker = async () => {
    const comlinkWrapperWorker = getDedicatedConvertWorker();
    return {
        comlink: await new comlinkWrapperWorker.comlink(),
        worker: comlinkWrapperWorker.worker,
    };
};
