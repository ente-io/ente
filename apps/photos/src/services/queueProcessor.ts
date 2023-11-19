import { CustomError } from '@ente/shared/error';

interface RequestQueueItem {
    request: (canceller?: RequestCanceller) => Promise<any>;
    successCallback: (response: any) => void;
    failureCallback: (error: Error) => void;
    isCanceled: { status: boolean };
    canceller: { exec: () => void };
}

export enum PROCESSING_STRATEGY {
    FIFO,
    LIFO,
}

export interface RequestCanceller {
    exec: () => void;
}

export interface CancellationStatus {
    status: boolean;
}

export default class QueueProcessor<T> {
    private requestQueue: RequestQueueItem[] = [];

    private requestInProcessing = 0;

    constructor(
        private maxParallelProcesses: number,
        private processingStrategy = PROCESSING_STRATEGY.FIFO
    ) {}

    public queueUpRequest(
        request: (canceller?: RequestCanceller) => Promise<T>
    ) {
        const isCanceled: CancellationStatus = { status: false };
        const canceller: RequestCanceller = {
            exec: () => {
                isCanceled.status = true;
            },
        };

        const promise = new Promise<T>((resolve, reject) => {
            this.requestQueue.push({
                request,
                successCallback: resolve,
                failureCallback: reject,
                isCanceled,
                canceller,
            });
            this.pollQueue();
        });

        return { promise, canceller };
    }

    private async pollQueue() {
        if (this.requestInProcessing < this.maxParallelProcesses) {
            this.requestInProcessing++;
            this.processQueue();
        }
    }

    private async processQueue() {
        while (this.requestQueue.length > 0) {
            const queueItem =
                this.processingStrategy === PROCESSING_STRATEGY.LIFO
                    ? this.requestQueue.pop()
                    : this.requestQueue.shift();
            let response = null;

            if (queueItem.isCanceled.status) {
                queueItem.failureCallback(Error(CustomError.REQUEST_CANCELLED));
            } else {
                try {
                    response = await queueItem.request(queueItem.canceller);
                    queueItem.successCallback(response);
                } catch (e) {
                    queueItem.failureCallback(e);
                }
            }
        }
        this.requestInProcessing--;
    }
}
