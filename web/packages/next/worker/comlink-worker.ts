import { ensureElectron } from "@/next/electron";
import log, { logToDisk } from "@/next/log";
import { expose, wrap, type Remote } from "comlink";
import { ensureLocalUser } from "../local-user";

/**
 * A minimal wrapper for a web {@link Worker}, proxying a class of type T.
 *
 * `comlink` is a library that simplies working with web workers by
 * transparently proxying objects across the boundary instead of us needing to
 * work directly with the raw postMessage interface.
 *
 * This class is a thin wrapper over a common usage pattern of comlink. It takes
 * a web worker ({@link Worker}) that is expected to have {@link expose}-ed a
 * class of type T. It then makes available the main thread handle to this class
 * as the {@link remote} property.
 *
 * It also exposes an object of type {@link WorkerBridge} _to_ the code running
 * inside the web worker.
 */
export class ComlinkWorker<T extends new () => InstanceType<T>> {
    public remote: Promise<Remote<InstanceType<T>>>;
    private worker: Worker;
    private name: string;

    constructor(name: string, worker: Worker) {
        this.name = name;
        this.worker = worker;

        worker.onerror = (event) => {
            log.error(
                `Got error event from worker: ${JSON.stringify({ event, name })}`,
            );
        };
        log.debug(() => `Created ${name} web worker`);
        const comlink = wrap<T>(worker);
        this.remote = new comlink() as Promise<Remote<InstanceType<T>>>;
        expose(workerBridge, worker);
    }

    public terminate() {
        this.worker.terminate();
        log.debug(() => `Terminated ${this.name} web worker`);
    }
}

/**
 * A set of utility functions that we expose to all workers that we create.
 *
 * Inside the worker's code, this can be accessed by using the sibling
 * `workerBridge` object after importing it from `worker-bridge.ts`.
 *
 * Not all workers need access to all these functions, and this can indeed be
 * done in a more fine-grained, per-worker, manner if needed. For now, since it
 * is a motley bunch, we just inject them all.
 */
const workerBridge = {
    // Needed by all workers (likely, not necessarily).
    logToDisk,
    // Needed by MLWorker.
    getAuthToken: () => ensureLocalUser().token,
    convertToJPEG: (imageData: Uint8Array) =>
        ensureElectron().convertToJPEG(imageData),
};

export type WorkerBridge = typeof workerBridge;
