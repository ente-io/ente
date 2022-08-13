import { runningInBrowser } from 'utils/common';
import { Remote, wrap, expose } from 'comlink';
import { DedicatedMLWorker } from 'worker/machineLearning.worker';
import { MachineLearningWorker } from 'types/machineLearning';
import ElectronCacheStorageProxy from 'services/workerElectronCache/workerElectronCacheStorageClient';

export class MLWorkerWithProxy {
    public proxy: Promise<Remote<MachineLearningWorker>>;
    private worker: Worker;
    private name: string;

    constructor(name: string) {
        this.name = name;
        if (!runningInBrowser()) {
            return;
        }
        this.worker = new Worker(
            new URL('worker/machineLearning.worker', import.meta.url),
            { name: 'ml-sync' }
        );
        this.worker.onerror = (errorEvent) => {
            console.error('Got error event from worker', errorEvent);
        };
        console.log(`Initiated ${this.name}`);
        const comlink = wrap<typeof DedicatedMLWorker>(this.worker);
        expose(ElectronCacheStorageProxy, this.worker);
        this.proxy = new comlink();
    }

    public terminate() {
        this.worker.terminate();
        console.log(`Terminated ${this.name}`);
    }
}
