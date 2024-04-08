import { logToDisk } from "@/next/log";
import { addLocalLog } from "@ente/shared/logging";
import { Remote, expose, wrap } from "comlink";
import ElectronAPIs from "@/next/electron";
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
        expose(workerBridge, worker);
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
 * Inside the worker's code, this can be accessed by using the sibling
 * `workerBridge` object by importing `worker-bridge.ts`.
 */
const workerBridge = {
    logToDisk,
    convertToJPEG: (inputFileData: Uint8Array, filename: string) =>
        ElectronAPIs.convertToJPEG(inputFileData, filename),
};

export type WorkerBridge = typeof workerBridge;
