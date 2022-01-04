import { MachineLearningWorker, MLSyncConfig } from 'types/machineLearning';
import { getMLSyncConfig } from 'utils/machineLearning';

class MLSyncJob {
    private mlSyncConfig: Promise<MLSyncConfig>;
    private intervalSec: number;
    private nextTimeoutId: ReturnType<typeof setTimeout>;

    constructor() {
        this.mlSyncConfig = getMLSyncConfig();
    }

    public async start(token: string, mlWorker: MachineLearningWorker) {
        if (!this.intervalSec) {
            await this.resetInterval();
        }

        if (this.nextTimeoutId) {
            this.stop();
        }

        this.nextTimeoutId = setTimeout(
            () => this.sync(token, mlWorker),
            this.intervalSec * 1000
        );
        console.log('Scheduled next ML Sync after: ', this.intervalSec);
    }

    private async sync(token: string, mlWorker: MachineLearningWorker) {
        this.nextTimeoutId = undefined;

        console.log('Running ML Sync');
        try {
            const results = await mlWorker.sync(token);
            const mlSyncConfig = await this.mlSyncConfig;
            if (results.nOutOfSyncFiles < 1) {
                this.intervalSec = Math.min(
                    mlSyncConfig.maxSyncIntervalSec,
                    this.intervalSec * 2
                );
            } else {
                this.intervalSec = mlSyncConfig.syncIntervalSec;
            }
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

    public async resetInterval() {
        const mlSyncConfig = await this.mlSyncConfig;
        this.intervalSec = mlSyncConfig.syncIntervalSec;
    }
}

export default MLSyncJob;
