import { Remote, wrap } from 'comlink';
import { addLocalLog } from 'utils/logging';

export class ComlinkWorker<T> {
    public remote: Remote<T>;
    private worker: Worker;
    private name: string;

    constructor(name: string, worker: Worker) {
        this.name = name;
        this.worker = worker;

        this.worker.onerror = (errorEvent) => {
            console.error('Got error event from worker', errorEvent);
        };
        addLocalLog(() => `Initiated ${this.name}`);
        this.remote = wrap<T>(this.worker);
    }

    public terminate() {
        this.worker.terminate();
        addLocalLog(() => `Terminated ${this.name}`);
    }
}
