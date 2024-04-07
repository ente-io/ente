import { haveWindow } from "@/next/env";
import { ComlinkWorker } from "@ente/shared/worker/comlinkWorker";
import { DedicatedMLWorker } from "worker/ml.worker";

export const getDedicatedMLWorker = (name: string) => {
    if (haveWindow()) {
        const cryptoComlinkWorker = new ComlinkWorker<typeof DedicatedMLWorker>(
            name ?? "ente-ml-worker",
            new Worker(new URL("worker/ml.worker.ts", import.meta.url)),
        );
        return cryptoComlinkWorker;
    }
};
