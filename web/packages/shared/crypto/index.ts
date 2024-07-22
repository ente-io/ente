import { ComlinkWorker } from "@/base/worker/comlink-worker";
import type { Remote } from "comlink";
import { type DedicatedCryptoWorker } from "./internal/crypto.worker";

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
        "ente-crypto-worker",
        new Worker(new URL("internal/crypto.worker.ts", import.meta.url)),
    );
    return cryptoComlinkWorker;
};

export default new ComlinkCryptoWorker();
