import { runningInBrowser } from 'utils/common';
import { wrap } from 'comlink';
import { DedicatedMLWorker } from 'worker/machineLearning.worker';
import { ComlinkWorker } from 'utils/crypto';

export function getDedicatedMLWorker(): ComlinkWorker {
    if (runningInBrowser()) {
        console.log('initiating worker');
        const worker = new Worker(
            new URL('worker/machineLearning.worker', import.meta.url),
            { name: 'ml-worker' }
        );
        console.log('initiated ml-worker', worker);
        const comlink = wrap<typeof DedicatedMLWorker>(worker);
        return { comlink, worker };
    }
}
