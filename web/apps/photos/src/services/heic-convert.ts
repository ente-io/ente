import { convertBytesToHumanReadable } from "@/next/file";
import log from "@/next/log";
import { ComlinkWorker } from "@/next/worker/comlink-worker";
import { CustomError } from "@ente/shared/error";
import { retryAsyncFunction } from "@ente/shared/utils";
import QueueProcessor from "@ente/shared/utils/queueProcessor";
import { type DedicatedHEICConvertWorker } from "worker/heic-convert.worker";

/**
 * Convert a HEIC image to a JPEG.
 *
 * Behind the scenes, it uses a web worker pool to do the conversion using a
 * WASM HEIC conversion package.
 *
 * @param heicBlob The HEIC blob to convert.
 * @returns The JPEG blob.
 */
export const heicToJPEG = (heicBlob: Blob) => converter.convert(heicBlob);

const WORKER_POOL_SIZE = 2;
const WAIT_TIME_BEFORE_NEXT_ATTEMPT_IN_MICROSECONDS = [100, 100];
const WAIT_TIME_IN_MICROSECONDS = 30 * 1000;
const BREATH_TIME_IN_MICROSECONDS = 1000;

class HEICConverter {
    private convertProcessor = new QueueProcessor<Blob>();
    private workerPool: ComlinkWorker<typeof DedicatedHEICConvertWorker>[] = [];

    private initIfNeeded() {
        if (this.workerPool.length > 0) return;
        this.workerPool = [];
        for (let i = 0; i < WORKER_POOL_SIZE; i++)
            this.workerPool.push(createComlinkWorker());
    }

    async convert(fileBlob: Blob): Promise<Blob> {
        this.initIfNeeded();

        const response = this.convertProcessor.queueUpRequest(() =>
            retryAsyncFunction<Blob>(async () => {
                const convertWorker = this.workerPool.shift();
                const worker = await convertWorker.remote;
                try {
                    const convertedHEIC = await new Promise<Blob>(
                        (resolve, reject) => {
                            const main = async () => {
                                try {
                                    const timeout = setTimeout(() => {
                                        reject(Error("wait time exceeded"));
                                    }, WAIT_TIME_IN_MICROSECONDS);
                                    const startTime = Date.now();
                                    const convertedHEIC =
                                        await worker.heicToJPEG(fileBlob);
                                    log.info(
                                        `originalFileSize:${convertBytesToHumanReadable(
                                            fileBlob?.size,
                                        )},convertedFileSize:${convertBytesToHumanReadable(
                                            convertedHEIC?.size,
                                        )},  heic conversion time: ${
                                            Date.now() - startTime
                                        }ms `,
                                    );
                                    clearTimeout(timeout);
                                    resolve(convertedHEIC);
                                } catch (e) {
                                    reject(e);
                                }
                            };
                            main();
                        },
                    );
                    if (!convertedHEIC || convertedHEIC?.size === 0) {
                        log.error(
                            `converted heic fileSize is Zero - ${JSON.stringify(
                                {
                                    originalFileSize:
                                        convertBytesToHumanReadable(
                                            fileBlob?.size ?? 0,
                                        ),
                                    convertedFileSize:
                                        convertBytesToHumanReadable(
                                            convertedHEIC?.size ?? 0,
                                        ),
                                },
                            )}`,
                        );
                    }
                    await new Promise((resolve) => {
                        setTimeout(
                            () => resolve(null),
                            BREATH_TIME_IN_MICROSECONDS,
                        );
                    });
                    this.workerPool.push(convertWorker);
                    return convertedHEIC;
                } catch (e) {
                    log.error("heic conversion failed", e);
                    convertWorker.terminate();
                    this.workerPool.push(createComlinkWorker());
                    throw e;
                }
            }, WAIT_TIME_BEFORE_NEXT_ATTEMPT_IN_MICROSECONDS),
        );

        try {
            return await response.promise;
        } catch (e) {
            if (e.message === CustomError.REQUEST_CANCELLED) {
                // ignore
                return null;
            }
            throw e;
        }
    }
}

/** The singleton instance of {@link HEICConverter}. */
const converter = new HEICConverter();

const createComlinkWorker = () =>
    new ComlinkWorker<typeof DedicatedHEICConvertWorker>(
        "heic-convert-worker",
        new Worker(new URL("worker/heic-convert.worker.ts", import.meta.url)),
    );
