import { runningInBrowser } from 'utils/common';
import { wrap } from 'comlink';
import { DedicatedMLWorker } from 'worker/machineLearning.worker';

export function getDedicatedMLWorker() {
    if (runningInBrowser()) {
        console.log('initiating worker');
        const worker = new Worker(
            new URL('worker/machineLearning.worker', import.meta.url),
            { name: 'ml-worker' }
        );
        console.log('initiated ml-worker', worker);
        return wrap<typeof DedicatedMLWorker>(worker);
    }
}
