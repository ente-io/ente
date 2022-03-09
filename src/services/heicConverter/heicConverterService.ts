import QueueProcessor from 'services/queueProcessor';
import { getDedicatedConvertWorker } from 'utils/comlink';
import { CustomError } from 'utils/error';
import { logError } from 'utils/sentry';

const WORKER_POOL_SIZE = 2;
const MAX_CONVERSION_IN_PARALLEL = 1;

class HEICConverter {
    private convertProcessor = new QueueProcessor<Blob>(
        MAX_CONVERSION_IN_PARALLEL
    );
    private workerPool: any[];
    private ready: Promise<void>;

    constructor() {
        this.ready = this.init();
    }
    async init() {
        this.workerPool = [];
        for (let i = 0; i < WORKER_POOL_SIZE; i++) {
            const worker = getDedicatedConvertWorker()?.comlink;
            if (!worker) {
                return;
            }
            this.workerPool.push({
                id: i,
                worker: await new worker(),
            });
        }
    }
    async convert(fileBlob: Blob, format = 'PNG'): Promise<Blob> {
        await this.ready;
        const response = this.convertProcessor.queueUpRequest(async () => {
            const { id, worker } = this.workerPool.shift();
            try {
                return await worker.convertHEIC(fileBlob, format);
            } finally {
                this.workerPool.push({ id, worker });
            }
        });
        try {
            return await response.promise;
        } catch (e) {
            if (e.message === CustomError.REQUEST_CANCELLED) {
                // ignore
                return null;
            } else {
                logError(e, 'heic conversion failed');
                throw e;
            }
        }
    }
}

export default new HEICConverter();
