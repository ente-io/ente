import { ComlinkWorker } from "@ente/shared/worker/comlinkWorker";
import { Remote } from "comlink";
import { runningInBrowser } from "utils/common";
import { DedicatedSearchWorker } from "worker/search.worker";

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
    if (runningInBrowser()) {
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
