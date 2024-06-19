import { ComlinkWorker } from "@/next/worker/comlink-worker";
import { wait } from "@/utils/promise";
import type { HEICConvertWorker } from "./heic-convert.worker";

/**
 * Convert a HEIC image to a JPEG.
 *
 * Behind the scenes, it uses a web worker to do the conversion using a WASM
 * HEIC conversion package.
 *
 * @param heicBlob The HEIC blob to convert.
 *
 * @returns The JPEG blob.
 */
export const heicToJPEG = async (heicBlob: Blob) =>
    worker()
        .then((w) => w.heicToJPEG(heicBlob))
        // I'm told this library used to have big memory spikes, and adding pauses
        // to get GC to run helped.
        .then((res) => wait(10 /* ms */).then(() => res));

/** Cached instance of the {@link ComlinkWorker} that wraps our web worker. */
let _comlinkWorker: ComlinkWorker<typeof HEICConvertWorker> | undefined;

/** Lazily created, cached, instance of our web worker. */
const worker = async () => {
    let comlinkWorker = _comlinkWorker;
    if (!comlinkWorker) _comlinkWorker = comlinkWorker = createComlinkWorker();
    return await comlinkWorker.remote;
};

const createComlinkWorker = () =>
    new ComlinkWorker<typeof HEICConvertWorker>(
        "heic-convert-worker",
        new Worker(new URL("heic-convert.worker.ts", import.meta.url)),
    );
