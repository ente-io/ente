import QueueProcessor from 'services/queueProcessor';
import { CustomError } from 'utils/error';
import { createNewConvertWorker } from 'utils/heicConverter';
import { retryAsyncFunction } from 'utils/network';
import { logError } from 'utils/sentry';
import { addLogLine } from 'utils/logging';

const WORKER_POOL_SIZE = 2;
const MAX_CONVERSION_IN_PARALLEL = 1;
const WAIT_TIME_BEFORE_NEXT_ATTEMPT_IN_MICROSECONDS = [100, 100];
const WAIT_TIME_IN_MICROSECONDS = 30 * 1000;
const BREATH_TIME_IN_MICROSECONDS = 1000;

class HEICConverter {
    private convertProcessor = new QueueProcessor<Blob>(
        MAX_CONVERSION_IN_PARALLEL
    );
    private workerPool: { comlink: any; worker: Worker }[];
    private ready: Promise<void>;

    constructor() {
        this.ready = this.init();
    }
    async init() {
        this.workerPool = [];
        for (let i = 0; i < WORKER_POOL_SIZE; i++) {
            this.workerPool.push(await createNewConvertWorker());
        }
    }
    async convert(fileBlob: Blob, format = 'JPEG'): Promise<Blob> {
        await this.ready;
        const response = this.convertProcessor.queueUpRequest(() =>
            retryAsyncFunction<Blob>(async () => {
                const { comlink, worker } = this.workerPool.shift();
                try {
                    const convertedHEIC = await new Promise<Blob>(
                        (resolve, reject) => {
                            const main = async () => {
                                try {
                                    const timeout = setTimeout(() => {
                                        reject(Error('wait time exceeded'));
                                    }, WAIT_TIME_IN_MICROSECONDS);
                                    const startTime = Date.now();
                                    const convertedHEIC: Blob =
                                        await comlink.convertHEIC(
                                            fileBlob,
                                            format
                                        );
                                    addLogLine(
                                        `originalFileSize:${
                                            fileBlob?.size
                                        },convertedFileSize:${
                                            convertedHEIC?.size
                                        },  heic conversion time: ${
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
                                originalFileSize: fileBlob?.size ?? 0,
                                convertedFileSize: convertedHEIC?.size ?? 0,
                            }
                        );
                    }
                    await new Promise((resolve) => {
                        setTimeout(
                            () => resolve(null),
                            BREATH_TIME_IN_MICROSECONDS
                        );
                    });
                    this.workerPool.push({ comlink, worker });
                    return convertedHEIC;
                } catch (e) {
                    addLogLine('heic conversion failed-' + e.message);
                    logError(e, 'heic conversion failed');
                    worker.terminate();
                    this.workerPool.push(await createNewConvertWorker());
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
