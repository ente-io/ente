import { runningInBrowser } from 'utils/common';
import { Remote, wrap } from 'comlink';
import { addLocalLog } from 'utils/logging';

export class ComlinkWorker<T> {
    public remote: Remote<T>;
    private worker: Worker;
    private name: string;

    constructor(name: string, url: URL) {
        this.name = name;
        if (!runningInBrowser()) {
            return;
        }
        this.worker = new Worker(url, { name: name });
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
