import { ComlinkWorker } from "ente-base/worker/comlink-worker";
import type { HEICConvertWorker } from "./heic-convert.worker";

/**
 * Convert a HEIC image to a JPEG.
 *
 * Behind the scenes, it uses a web worker to do the conversion using a Wasm
 * HEIC conversion package.
 *
 * @param heicBlob The HEIC blob to convert.
 *
 * @returns The JPEG blob.
 */
export const heicToJPEG = async (heicBlob: Blob) =>
    worker().then((w) => w.heicToJPEG(heicBlob));

/** Cached instance of the {@link ComlinkWorker} that wraps our web worker. */
let _comlinkWorker: ComlinkWorker<typeof HEICConvertWorker> | undefined;

/** Lazily created, cached, instance of our web worker. */
const worker = async () => (_comlinkWorker ??= createComlinkWorker()).remote;

const createComlinkWorker = () =>
    new ComlinkWorker<typeof HEICConvertWorker>(
        "heic-convert-worker",
        new Worker(new URL("heic-convert.worker.ts", import.meta.url)),
    );
