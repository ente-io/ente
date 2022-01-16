import { runningInBrowser } from 'utils/common';
import { Remote, wrap } from 'comlink';
import { DedicatedMLWorker } from 'worker/machineLearning.worker';
import { MachineLearningWorker } from 'types/machineLearning';

export class MLWorkerWithProxy {
    public proxy: Promise<Remote<MachineLearningWorker>>;
    private worker: Worker;

    constructor() {
        if (!runningInBrowser()) {
            return;
        }
        this.worker = new Worker(
            new URL('worker/machineLearning.worker', import.meta.url),
            { name: 'ml-worker' }
        );
        this.worker.onerror = (errorEvent) => {
            console.error('Got error event from worker', errorEvent);
        };
        console.log('Initiated ml-worker');
        const comlink = wrap<typeof DedicatedMLWorker>(this.worker);
        this.proxy = new comlink();
    }

    public terminate() {
        this.worker.terminate();
        console.log('Terminated ml-worker');
    }
}
