import { Remote } from 'comlink';
import { DedicatedConvertWorker } from 'worker/convert.worker';
import { ComlinkWorker } from './comlinkWorker';
import { runningInBrowser } from '@ente/shared/platform';

class ComlinkConvertWorker {
    private comlinkWorkerInstance: Remote<DedicatedConvertWorker>;

    async getInstance() {
        if (!this.comlinkWorkerInstance) {
            this.comlinkWorkerInstance = await getDedicatedConvertWorker()
                .remote;
        }
        return this.comlinkWorkerInstance;
    }
}

export const getDedicatedConvertWorker = () => {
    if (runningInBrowser()) {
        const cryptoComlinkWorker = new ComlinkWorker<
            typeof DedicatedConvertWorker
        >(
            'ente-convert-worker',
            new Worker(new URL('worker/convert.worker.ts', import.meta.url))
        );
        return cryptoComlinkWorker;
    }
};

export default new ComlinkConvertWorker();
