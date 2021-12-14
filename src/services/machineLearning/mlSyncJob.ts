import { MachineLearningWorker } from 'types/machineLearning';
import { getMLSyncConfig } from 'utils/machineLearning';

class MLSyncJob {
    private nextTimeoutId: ReturnType<typeof setTimeout>;

    constructor() {}

    public async start(token: string, mlWorker: MachineLearningWorker) {
        const mlSyncConfig = await getMLSyncConfig();

        if (this.nextTimeoutId) {
            this.stop();
        }

        this.nextTimeoutId = setTimeout(
            () => this.sync(token, mlWorker),
            mlSyncConfig.syncIntervalSec * 1000
        );
        console.log(
            'Scheduled next ML Sync after: ',
            mlSyncConfig.syncIntervalSec
        );
    }

    private async sync(token: string, mlWorker: MachineLearningWorker) {
        this.nextTimeoutId = undefined;

        // const mlSyncConfig = await mlService.getMLSyncConfig();
        console.log('Running ML Sync');
        try {
            const results = await mlWorker.sync(token);
            console.log('Ran machine learning sync from worker', results);
        } catch (e) {
            console.error('Error while running MLSync: ', e);
        } finally {
            this.start(token, mlWorker);
        }
    }

    public async stop() {
        if (!this.nextTimeoutId) {
            return;
        }

        clearTimeout(this.nextTimeoutId);
        this.nextTimeoutId = undefined;
        console.log('Cancelled next scheduled ML Sync');
    }
}

export default MLSyncJob;
