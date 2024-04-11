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

// TODO(MR): Temporary method to forward auth tokens to workers
const getAuthToken = () => {
    // LS_KEYS.USER
    const userJSONString = localStorage.getItem("user");
    if (!userJSONString) return undefined;
    const json: unknown = JSON.parse(userJSONString);
    if (!json || typeof json != "object" || !("token" in json))
        return undefined;
    const token = json.token;
    if (typeof token != "string") return undefined;
    return token;
};

/**
 * A minimal set of utility functions that we expose to all workers that we
 * create.
 *
 * Inside the worker's code, this can be accessed by using the sibling
 * `workerBridge` object after importing it from `worker-bridge.ts`.
 */
const workerBridge = {
    logToDisk,
    getAuthToken,
    convertToJPEG: (inputFileData: Uint8Array, filename: string) =>
        ensureElectron().convertToJPEG(inputFileData, filename),
    detectFaces: (input: Float32Array) => ensureElectron().detectFaces(input),
    faceEmbedding: (input: Float32Array) =>
        ensureElectron().faceEmbedding(input),
};

export type WorkerBridge = typeof workerBridge;
