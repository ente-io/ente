import { expose, wrap, type Remote } from "comlink";
import { ensureElectron } from "ente-base/electron";
import log, { logToDisk } from "ente-base/log";

/**
 * A minimal wrapper for a web {@link Worker}, proxying a class of type T.
 *
 * `comlink` is a library that simplifies working with web workers by
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
 *
 * It all gets a bit confusing sometimes, so here is a legend of the parties
 * involved:
 *
 * -  ComlinkWorker (wraps the web worker)
 * -  Web `Worker` (exposes class T)
 * -  ComlinkWorker.remote (the exposed class T running inside the web worker)
 */
export class ComlinkWorker<T extends new () => InstanceType<T>> {
    /** The class (T) exposed by the web worker */
    public remote: Promise<Remote<InstanceType<T>>>;
    /** The web worker */
    public worker: Worker;
    /** An arbitrary name associated with this ComlinkWorker for debugging. */
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
 * A set of utility functions that we expose to all web workers that we create.
 *
 * Inside the worker's code, this can be accessed by using the sibling
 * `workerBridge` object after importing it from `worker-bridge.ts`.
 *
 * Not all workers need access to all these functions, and this can indeed be
 * done in a more fine-grained, per-worker, manner if needed. For now, since it
 * is just a couple, we just inject them all to all workers.
 */
const workerBridge = {
    // Needed by all workers (likely, but not necessarily).
    logToDisk,
    // Needed by ML worker.
    convertToJPEG: (imageData: Uint8Array) =>
        ensureElectron().convertToJPEG(imageData),
};

export type WorkerBridge = typeof workerBridge;
