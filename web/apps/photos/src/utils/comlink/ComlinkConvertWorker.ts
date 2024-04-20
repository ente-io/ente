import { haveWindow } from "@/next/env";
import { ComlinkWorker } from "@/next/worker/comlink-worker";
import { type DedicatedConvertWorker } from "worker/convert.worker";

export const getDedicatedConvertWorker = () => {
    if (haveWindow()) {
        const cryptoComlinkWorker = new ComlinkWorker<
            typeof DedicatedConvertWorker
        >(
            "ente-convert-worker",
            new Worker(new URL("worker/convert.worker.ts", import.meta.url)),
        );
        return cryptoComlinkWorker;
    }
};
