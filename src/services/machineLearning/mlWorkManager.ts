import debounce from 'debounce-promise';
import PQueue from 'p-queue';
import { eventBus, Events } from 'services/events';
import { File, FILE_TYPE } from 'services/fileService';
import { FACE_CROPS_CACHE_NAME, MLSyncConfig } from 'types/machineLearning';
import { getToken } from 'utils/common/key';
import { logQueueStats } from 'utils/machineLearning';
import { getMLSyncJobConfig } from 'utils/machineLearning/config';
import { MLWorkerWithProxy } from 'utils/machineLearning/worker';
import { logError } from 'utils/sentry';
import mlIDbStorage from 'utils/storage/mlIDbStorage';
import { MLSyncJobResult, MLSyncJob } from './mlSyncJob';

const LIVE_SYNC_IDLE_DEBOUNCE_SEC = 30;
const LIVE_SYNC_QUEUE_TIMEOUT_SEC = 300;
const LOCAL_FILES_UPDATED_DEBOUNCE_SEC = 30;

class MLWorkManager {
    private mlSyncJob: MLSyncJob;
    private syncJobWorker: MLWorkerWithProxy;

    private liveSyncQueue: PQueue;
    private liveSyncWorker: MLWorkerWithProxy;

    constructor() {
        this.liveSyncQueue = new PQueue({
            concurrency: 1,
            // TODO: temp, remove
            timeout: LIVE_SYNC_QUEUE_TIMEOUT_SEC * 1000,
            throwOnTimeout: true,
        });
        logQueueStats(this.liveSyncQueue, 'livesync');

        const debouncedLiveSyncIdle = debounce(
            () => this.onLiveSyncIdle(),
            LIVE_SYNC_IDLE_DEBOUNCE_SEC * 1000
        );
        this.liveSyncQueue.on('idle', () => debouncedLiveSyncIdle(), this);

        eventBus.on(Events.APP_START, this.appStartHandler, this);

        eventBus.on(Events.LOGIN, this.startSyncJob, this);

        eventBus.on(Events.LOGOUT, this.logoutHandler, this);

        eventBus.on(Events.FILE_UPLOADED, this.fileUploadedHandler, this);

        const debouncedFilesUpdated = debounce(
            () => this.localFilesUpdatedHandler(),
            LOCAL_FILES_UPDATED_DEBOUNCE_SEC * 1000
        );
        eventBus.on(
            Events.LOCAL_FILES_UPDATED,
            () => debouncedFilesUpdated(),
            this
        );
    }

    // Handlers
    private async appStartHandler() {
        console.log('appStartHandler');
        try {
            this.startSyncJob();
        } catch (e) {
            logError(e, 'Failed in ML appStart Handler');
        }
    }

    private async logoutHandler() {
        console.log('logoutHandler');
        try {
            await this.stopSyncJob();
            this.mlSyncJob = undefined;
            this.terminateLiveSyncWorker();
            await mlIDbStorage.clearMLDB();
            await caches.delete(FACE_CROPS_CACHE_NAME);
        } catch (e) {
            logError(e, 'Failed in ML logout Handler');
        }
    }

    private async fileUploadedHandler(arg: {
        enteFile: File;
        localFile: globalThis.File;
    }) {
        console.log('fileUploadedHandler');
        if (arg.enteFile.metadata.fileType !== FILE_TYPE.IMAGE) {
            console.log('Skipping non image file for local file processing');
            return;
        }
        try {
            await this.syncLocalFile(arg.enteFile, arg.localFile);
        } catch (error) {
            console.error('Error in syncLocalFile', error);
            this.liveSyncQueue.clear();
            // logError(e, 'Failed in ML fileUploaded Handler');
        }
    }

    private async localFilesUpdatedHandler() {
        console.log('Local files updated');
        this.startSyncJob();
    }

    // Live Sync
    private async getLiveSyncWorker() {
        if (!this.liveSyncWorker) {
            this.liveSyncWorker = new MLWorkerWithProxy();
        }

        return this.liveSyncWorker.proxy;
    }

    private terminateLiveSyncWorker() {
        this.liveSyncWorker?.terminate();
        this.liveSyncWorker = undefined;
    }

    private onLiveSyncIdle() {
        console.log('Live sync idle');
        this.terminateLiveSyncWorker();
        this.startSyncJob();
    }

    public async syncLocalFile(
        enteFile: File,
        localFile: globalThis.File,
        config?: MLSyncConfig
    ) {
        const result = await this.liveSyncQueue.add(async () => {
            this.stopSyncJob();
            const token = getToken();
            const mlWorker = await this.getLiveSyncWorker();
            return mlWorker.syncLocalFile(token, enteFile, localFile, config);
        });

        if ('message' in result) {
            // TODO: redirect/refresh to gallery in case of session_expired
            // may not be required as uploader should anyways take care of this
            console.error('Error while syncing local file: ', result);
        }
    }

    // Sync Job
    private async getSyncJobWorker() {
        if (!this.syncJobWorker) {
            this.syncJobWorker = new MLWorkerWithProxy();
        }

        return this.syncJobWorker.proxy;
    }

    private terminateSyncJobWorker() {
        this.syncJobWorker?.terminate();
        this.syncJobWorker = undefined;
    }

    private async runMLSyncJob() {
        const token = getToken();
        const jobWorkerProxy = await this.getSyncJobWorker();

        const mlSyncResult = await jobWorkerProxy.sync(token);

        this.terminateSyncJobWorker();
        const jobResult: MLSyncJobResult = {
            shouldBackoff:
                !!mlSyncResult.error || mlSyncResult.nOutOfSyncFiles < 1,
            mlSyncResult,
        };
        console.log('ML Sync Job result: ', jobResult);

        // TODO: redirect/refresh to gallery in case of session_expired, stop ml sync job

        return jobResult;
    }

    public async startSyncJob() {
        try {
            console.log('MLWorkManager.startSyncJob');
            if (!getToken()) {
                console.log('User not logged in, not starting ml sync job');
                return;
            }
            const mlSyncJobConfig = await getMLSyncJobConfig();
            if (!this.mlSyncJob) {
                this.mlSyncJob = new MLSyncJob(mlSyncJobConfig, () =>
                    this.runMLSyncJob()
                );
            }
            this.mlSyncJob.start();
        } catch (e) {
            logError(e, 'Failed to start MLSync Job');
        }
    }

    public stopSyncJob(terminateWorker: boolean = true) {
        try {
            console.log('MLWorkManager.stopSyncJob');
            this.mlSyncJob.stop();
            terminateWorker && this.terminateSyncJobWorker();
        } catch (e) {
            logError(e, 'Failed to stop MLSync Job');
        }
    }
}

export default new MLWorkManager();
