import { ComlinkWorker } from "@/base/worker/comlink-worker";
import type { CryptoWorker } from "./worker";

/** Cached instance of the {@link ComlinkWorker} that wraps our web worker. */
let _comlinkWorker: ComlinkWorker<typeof CryptoWorker> | undefined;

/**
 * Lazily created, cached, instance of a CryptoWorker web worker.
 */
export const sharedCryptoWorker = async () =>
    (_comlinkWorker ??= createComlinkWorker()).remote;

const createComlinkWorker = () =>
    new ComlinkWorker<typeof CryptoWorker>(
        "Crypto",
        new Worker(new URL("worker.ts", import.meta.url)),
    );
