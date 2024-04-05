import { CustomError } from "@ente/shared/error";

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

export interface CancellationStatus {
    status: boolean;
}

export default class QueueProcessor<T> {
    private requestQueue: RequestQueueItem[] = [];
    private isProcessingRequest = false;

    public queueUpRequest(
        request: (canceller?: RequestCanceller) => Promise<T>,
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

            this.processQueueIfNeeded();
        });

        return { promise, canceller };
    }

    private async processQueueIfNeeded() {
        if (this.isProcessingRequest) return;
        this.isProcessingRequest = true;

        while (this.requestQueue.length > 0) {
            const queueItem = this.requestQueue.shift();
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

        this.isProcessingRequest = false;
    }
}
