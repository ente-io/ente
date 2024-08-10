import { ComlinkWorker } from "@/base/worker/comlink-worker";
import type { Remote } from "comlink";
import { type DedicatedCryptoWorker } from "./worker";

class ComlinkCryptoWorker {
    private comlinkWorkerInstance:
        | Promise<Remote<DedicatedCryptoWorker>>
        | undefined;

    async getInstance() {
        if (!this.comlinkWorkerInstance) {
            const comlinkWorker = getDedicatedCryptoWorker();
            this.comlinkWorkerInstance = comlinkWorker.remote;
        }
        return this.comlinkWorkerInstance;
    }
}

export const getDedicatedCryptoWorker = () => {
    const cryptoComlinkWorker = new ComlinkWorker<typeof DedicatedCryptoWorker>(
        "Crypto",
        new Worker(new URL("./worker.ts", import.meta.url)),
    );
    return cryptoComlinkWorker;
};

export default new ComlinkCryptoWorker();
