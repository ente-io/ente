import { ComlinkWorker } from "@/base/worker/comlink-worker";
import type { CryptoWorker } from "./worker";

/**
 * Cached instance of the {@link ComlinkWorker} that wraps our web worker.
 */
let _comlinkWorker: ComlinkWorker<typeof CryptoWorker> | undefined;

/**
 * Lazily created, cached, instance of a CryptoWorker web worker.
 */
export const sharedCryptoWorker = async () =>
    (_comlinkWorker ??= createComlinkCryptoWorker()).remote;

/**
 * Create a new instance of a comlink worker that wraps a {@link CryptoWorker}
 * web worker.
 */
export const createComlinkCryptoWorker = () =>
    new ComlinkWorker<typeof CryptoWorker>(
        "crypto",
        new Worker(new URL("worker.ts", import.meta.url)),
    );
