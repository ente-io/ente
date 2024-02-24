import { WorkerSafeElectronClient } from "@ente/shared/electron/worker/client";
import { addLocalLog } from "@ente/shared/logging";
import { expose, Remote, wrap } from "comlink";
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
        expose(WorkerSafeElectronClient, this.worker);
    }

    public getName() {
        return this.name;
    }

    public terminate() {
        this.worker.terminate();
        addLocalLog(() => `Terminated ${this.name}`);
    }
}
