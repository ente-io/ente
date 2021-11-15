import { CustomError } from 'utils/common/errorUtil';

interface RequestQueueItem {
    request: (canceller?: RequestCanceller) => Promise<any>;
    successCallback: (response: any) => void;
    failureCallback: (error: Error) => void;
    isCanceled: { status: boolean };
    canceller: { exec: () => void };
}

export interface RequestCanceller {
    exec: () => void;
}

export default class QueueProcessor<T> {
    private requestQueue: RequestQueueItem[] = [];

    private requestInProcessing = 0;

    constructor(private maxParallelProcesses: number) {}

    public queueUpRequest(
        request: (canceller?: RequestCanceller) => Promise<T>
    ) {
        const isCanceled = { status: false };
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

    async pollQueue() {
        if (this.requestInProcessing < this.maxParallelProcesses) {
            this.requestInProcessing++;
            await this.processQueue();
            this.requestInProcessing--;
        }
    }

    public async processQueue() {
        while (this.requestQueue.length > 0) {
            const queueItem = this.requestQueue.pop();
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
    }
}
