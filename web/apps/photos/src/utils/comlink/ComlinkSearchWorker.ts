import { haveWindow } from "@/base/env";
import { ComlinkWorker } from "@/base/worker/comlink-worker";
import type { Remote } from "comlink";
import { type DedicatedSearchWorker } from "worker/search.worker";

class ComlinkSearchWorker {
    private comlinkWorkerInstance: Remote<DedicatedSearchWorker>;
    private comlinkWorker: ComlinkWorker<typeof DedicatedSearchWorker>;

    async getInstance() {
        if (!this.comlinkWorkerInstance) {
            if (!this.comlinkWorker)
                this.comlinkWorker = getDedicatedSearchWorker();
            this.comlinkWorkerInstance = await this.comlinkWorker.remote;
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
