import { expose, wrap, type Remote } from "comlink";
import log, { logToDisk } from "ente-base/log";

export class ComlinkWorker<T extends new () => InstanceType<T>> {
    public remote: Promise<Remote<InstanceType<T>>>;
    public worker: Worker;
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

const workerBridge = {
    logToDisk,
};

export type WorkerBridge = typeof workerBridge;
