import { haveWindow } from "@/next/env";
import { ComlinkWorker } from "@/next/worker/comlink-worker";
import { Remote } from "comlink";
import { type DedicatedSearchWorker } from "worker/search.worker";

class ComlinkSearchWorker {
    private comlinkWorkerInstance: Remote<DedicatedSearchWorker>;

    async getInstance() {
        if (!this.comlinkWorkerInstance) {
            this.comlinkWorkerInstance =
                await getDedicatedSearchWorker().remote;
        }
        return this.comlinkWorkerInstance;
    }
}

export const getDedicatedSearchWorker = () => {
    if (haveWindow()) {
        const cryptoComlinkWorker = new ComlinkWorker<
            typeof DedicatedSearchWorker
        >(
            "ente-search-worker",
            new Worker(new URL("worker/search.worker.ts", import.meta.url)),
        );
        return cryptoComlinkWorker;
    }
};

export default new ComlinkSearchWorker();
