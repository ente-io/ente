import { addLocalLog, logToDisk } from "@ente/shared/logging";
import { Remote, expose, wrap } from "comlink";
import { logError } from "../sentry";

export class ComlinkWorker<T extends new () => InstanceType<T>> {
    public remote: Promise<Remote<InstanceType<T>>>;
    private worker: Worker;
    private name: string;

    constructor(name: string, worker: Worker) {
        this.name = name;
        this.worker = worker;

        this.worker.onerror = (errorEvent) => {
            logError(Error(errorEvent.message), "Got error event from worker", {
                errorEvent: JSON.stringify(errorEvent),
                name: this.name,
            });
        };
        addLocalLog(() => `Initiated ${this.name}`);
        const comlink = wrap<T>(this.worker);
        this.remote = new comlink() as Promise<Remote<InstanceType<T>>>;
        // expose(WorkerSafeElectronClient, this.worker);
        expose(workerBridge, this.worker);
    }

    public getName() {
        return this.name;
    }

    public terminate() {
        this.worker.terminate();
        addLocalLog(() => `Terminated ${this.name}`);
    }
}

/**
 * A minimal set of utility functions that we expose to all workers that we
 * create.
 *
 * Inside the worker's code, this can be accessed by
 * `wrap<WorkerBridge>(self).foo`.
 */
const workerBridge = {
    logToDisk,
};

export type WorkerBridge = typeof workerBridge;
