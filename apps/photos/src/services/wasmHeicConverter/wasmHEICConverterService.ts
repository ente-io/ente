import QueueProcessor from 'services/queueProcessor';
import { CustomError } from '@ente/shared/error';
import { retryAsyncFunction } from 'utils/network';
import { logError } from '@ente/shared/sentry';
import { addLogLine } from '@ente/shared/logging';
import { DedicatedConvertWorker } from 'worker/convert.worker';
import { ComlinkWorker } from '@ente/shared/worker/comlinkWorker';
import { convertBytesToHumanReadable } from '@ente/shared/utils/size';
import { getDedicatedConvertWorker } from 'utils/comlink/ComlinkConvertWorker';

const WORKER_POOL_SIZE = 2;
const MAX_CONVERSION_IN_PARALLEL = 1;
const WAIT_TIME_BEFORE_NEXT_ATTEMPT_IN_MICROSECONDS = [100, 100];
const WAIT_TIME_IN_MICROSECONDS = 30 * 1000;
const BREATH_TIME_IN_MICROSECONDS = 1000;
const CONVERT_FORMAT = 'JPEG';

class HEICConverter {
    private convertProcessor = new QueueProcessor<Blob>(
        MAX_CONVERSION_IN_PARALLEL
    );
    private workerPool: ComlinkWorker<typeof DedicatedConvertWorker>[] = [];
    private ready: Promise<void>;

    constructor() {
        this.ready = this.init();
    }
    private async init() {
        this.workerPool = [];
        for (let i = 0; i < WORKER_POOL_SIZE; i++) {
            this.workerPool.push(getDedicatedConvertWorker());
        }
    }
    async convert(fileBlob: Blob): Promise<Blob> {
        await this.ready;
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
                                        reject(Error('wait time exceeded'));
                                    }, WAIT_TIME_IN_MICROSECONDS);
                                    const startTime = Date.now();
                                    const convertedHEIC =
                                        await worker.convertHEIC(
                                            fileBlob,
                                            CONVERT_FORMAT
                                        );
                                    addLogLine(
                                        `originalFileSize:${convertBytesToHumanReadable(
                                            fileBlob?.size
                                        )},convertedFileSize:${convertBytesToHumanReadable(
                                            convertedHEIC?.size
                                        )},  heic conversion time: ${
                                            Date.now() - startTime
                                        }ms `
                                    );
                                    clearTimeout(timeout);
                                    resolve(convertedHEIC);
                                } catch (e) {
                                    reject(e);
                                }
                            };
                            main();
                        }
                    );
                    if (!convertedHEIC || convertedHEIC?.size === 0) {
                        logError(
                            Error(`converted heic fileSize is Zero`),
                            'converted heic fileSize is Zero',
                            {
                                originalFileSize: convertBytesToHumanReadable(
                                    fileBlob?.size ?? 0
                                ),
                                convertedFileSize: convertBytesToHumanReadable(
                                    convertedHEIC?.size ?? 0
                                ),
                            }
                        );
                    }
                    await new Promise((resolve) => {
                        setTimeout(
                            () => resolve(null),
                            BREATH_TIME_IN_MICROSECONDS
                        );
                    });
                    this.workerPool.push(convertWorker);
                    return convertedHEIC;
                } catch (e) {
                    logError(e, 'heic conversion failed');
                    convertWorker.terminate();
                    this.workerPool.push(getDedicatedConvertWorker());
                    throw e;
                }
            }, WAIT_TIME_BEFORE_NEXT_ATTEMPT_IN_MICROSECONDS)
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

export default new HEICConverter();
