import { expose } from 'comlink';
import MachineLearningService from 'services/machineLearning/machineLearningService';
import { runningInWorker } from 'utils/common';
import { DEFAULT_ML_SYNC_CONFIG } from 'utils/machineLearning';

class MachineLearningWorker {
    mlService;
    nextMLSyncTimeoutId;

    async getMLService() {
        if (!this.mlService) {
            this.mlService = new MachineLearningService();
            await this.mlService.init();
        }

        return this.mlService;
    }

    getMLSyncConfig() {
        return DEFAULT_ML_SYNC_CONFIG;
    }

    // updateMLSyncConfig(config) {

    // }

    scheduleNextMLSync(token) {
        if (this.nextMLSyncTimeoutId) {
            this.cancelNextMLSync();
        }

        const mlSyncConfig = this.getMLSyncConfig();
        this.nextMLSyncTimeoutId = setTimeout(
            this.sync.bind(this, token),
            mlSyncConfig.syncIntervalSec * 1000
        );
        console.log(
            'Scheduled next ML Sync after: ',
            mlSyncConfig.syncIntervalSec
        );
    }

    async cancelNextMLSync() {
        clearTimeout(this.nextMLSyncTimeoutId);
        this.nextMLSyncTimeoutId = undefined;
        console.log('Cancelled next scheduled ML Sync');
    }

    async sync(token) {
        if (!runningInWorker()) {
            console.error(
                'MachineLearning worker will only run in web worker env.'
            );
            return;
        }

        const mlService = await this.getMLService();
        const mlSyncConfig = this.getMLSyncConfig();
        console.log(
            'Running machine learning sync from worker with config: ',
            mlSyncConfig
        );
        try {
            const results = await mlService.sync(token, mlSyncConfig);
            console.log('Ran machine learning sync from worker', results);
        } catch (e) {
            console.error('Error while running MLSync: ', e);
        } finally {
            this.scheduleNextMLSync(token);
        }
    }
}

expose(MachineLearningWorker, self);
