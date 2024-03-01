import { Remote } from "comlink";
import { DedicatedCryptoWorker } from "worker/crypto.worker";
import { ComlinkWorker } from "./comlinkWorker";

class ComlinkCryptoWorker {
    private comlinkWorkerInstance: Promise<Remote<DedicatedCryptoWorker>>;

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
        new Worker(new URL("worker/crypto.worker.ts", import.meta.url)),
    );
    return cryptoComlinkWorker;
};

export default new ComlinkCryptoWorker();
