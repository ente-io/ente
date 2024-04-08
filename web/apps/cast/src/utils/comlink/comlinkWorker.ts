import { Remote, wrap } from "comlink";
import log from "@/next/log";

export class ComlinkWorker<T extends new () => InstanceType<T>> {
    public remote: Promise<Remote<InstanceType<T>>>;
    private worker: Worker;
    private name: string;

    constructor(name: string, worker: Worker) {
        this.name = name;
        this.worker = worker;

        this.worker.onerror = (errorEvent) => {
            console.error("Got error event from worker", errorEvent);
        };
        log.debug(() => `Initiated ${this.name}`);
        const comlink = wrap<T>(this.worker);
        this.remote = new comlink() as Promise<Remote<InstanceType<T>>>;
    }

    public terminate() {
        this.worker.terminate();
        log.debug(() => `Terminated ${this.name}`);
    }
}
