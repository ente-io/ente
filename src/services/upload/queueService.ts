import { RequestCanceller } from 'services/HTTPService';

interface RequestQueueItem {
    request: (canceller?: RequestCanceller) => any;
    callback: (response) => void;
    isCanceled: { status: boolean };
    canceller: { exec: () => void };
}

export default class QueueService {
    private requestQueue: RequestQueueItem[] = [];

    private requestInProcessing = 0;

    constructor(private maxParallelProcesses: number) {}

    public queueUpRequest(request: () => any) {
        const isCanceled = { status: false };
        const canceller: RequestCanceller = {
            exec: () => {
                isCanceled.status = true;
            },
        };

        const response = new Promise<string>((resolve) => {
            this.requestQueue.push({
                request,
                callback: resolve,
                isCanceled,
                canceller,
            });
            this.pollQueue();
        });

        return { response, canceller };
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
            let response: string;

            if (queueItem.isCanceled.status) {
                response = null;
            } else {
                response = await queueItem.request(queueItem.canceller);
            }
            queueItem.callback(response);
            await this.processQueue();
        }
    }
}
