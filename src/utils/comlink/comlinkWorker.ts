import { expose, Remote, wrap } from 'comlink';
import { WorkerElectronCacheStorageClient } from 'services/workerElectronCache/client';
import { addLocalLog } from 'utils/logging';

export class ComlinkWorker<T extends new () => InstanceType<T>> {
    public remote: Promise<Remote<InstanceType<T>>>;
    private worker: Worker;
    private name: string;

    constructor(name: string, worker: Worker) {
        this.name = name;
        this.worker = worker;

        this.worker.onerror = (errorEvent) => {
            console.error('Got error event from worker', errorEvent);
        };
        addLocalLog(() => `Initiated ${this.name}`);
        const comlink = wrap<T>(this.worker);
        this.remote = new comlink() as Promise<Remote<InstanceType<T>>>;
        expose(WorkerElectronCacheStorageClient, this.worker);
    }

    public terminate() {
        this.worker.terminate();
        addLocalLog(() => `Terminated ${this.name}`);
    }
}
