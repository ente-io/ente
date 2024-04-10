import { ensureElectron } from "@/next/electron";
import log, { logToDisk } from "@/next/log";
import { expose, wrap, type Remote } from "comlink";

export class ComlinkWorker<T extends new () => InstanceType<T>> {
    public remote: Promise<Remote<InstanceType<T>>>;
    private worker: Worker;
    private name: string;

    constructor(name: string, worker: Worker) {
        this.name = name;
        this.worker = worker;

        this.worker.onerror = (ev) => {
            log.error(
                `Got error event from worker: ${JSON.stringify({
                    errorEvent: JSON.stringify(ev),
                    name: this.name,
                })}`,
            );
        };
        log.debug(() => `Initiated ${this.name}`);
        const comlink = wrap<T>(this.worker);
        this.remote = new comlink() as Promise<Remote<InstanceType<T>>>;
        expose(workerBridge, worker);
    }

    public getName() {
        return this.name;
    }

    public terminate() {
        this.worker.terminate();
        log.debug(() => `Terminated ${this.name}`);
    }
}

/**
 * A minimal set of utility functions that we expose to all workers that we
 * create.
 *
 * Inside the worker's code, this can be accessed by using the sibling
 * `workerBridge` object after importing it from `worker-bridge.ts`.
 */
const workerBridge = {
    logToDisk,
    convertToJPEG: (inputFileData: Uint8Array, filename: string) =>
        ensureElectron().convertToJPEG(inputFileData, filename),
};

export type WorkerBridge = typeof workerBridge;
