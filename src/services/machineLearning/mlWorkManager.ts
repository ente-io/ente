import debounce from 'debounce-promise';
import PQueue from 'p-queue';
import { eventBus, Events } from 'services/events';
import { EnteFile } from 'types/file';
import { FILE_TYPE } from 'constants/file';
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

    private debouncedLiveSyncIdle: () => void;
    private debouncedFilesUpdated: () => void;

    private liveSyncQueue: PQueue;
    private liveSyncWorker: MLWorkerWithProxy;
    private mlSearchEnabled: boolean;

    constructor() {
        this.liveSyncQueue = new PQueue({
            concurrency: 1,
            // TODO: temp, remove
            timeout: LIVE_SYNC_QUEUE_TIMEOUT_SEC * 1000,
            throwOnTimeout: true,
        });
        this.mlSearchEnabled = false;

        eventBus.on(Events.LOGOUT, this.logoutHandler, this);
        this.debouncedLiveSyncIdle = debounce(
            () => this.onLiveSyncIdle(),
            LIVE_SYNC_IDLE_DEBOUNCE_SEC * 1000
        );
        this.debouncedFilesUpdated = debounce(
            () => this.mlSearchEnabled && this.localFilesUpdatedHandler(),
            LOCAL_FILES_UPDATED_DEBOUNCE_SEC * 1000
        );
    }

    public async setMlSearchEnabled(enabled: boolean) {
        if (!this.mlSearchEnabled && enabled) {
            console.log('Enabling MLWorkManager');
            this.mlSearchEnabled = true;

            logQueueStats(this.liveSyncQueue, 'livesync');
            this.liveSyncQueue.on('idle', this.debouncedLiveSyncIdle, this);

            // eventBus.on(Events.APP_START, this.appStartHandler, this);
            // eventBus.on(Events.LOGIN, this.startSyncJob, this);
            eventBus.on(Events.FILE_UPLOADED, this.fileUploadedHandler, this);
            eventBus.on(
                Events.LOCAL_FILES_UPDATED,
                this.debouncedFilesUpdated,
                this
            );

            await this.startSyncJob();
        } else if (this.mlSearchEnabled && !enabled) {
            console.log('Disabling MLWorkManager');
            this.mlSearchEnabled = false;

            this.liveSyncQueue.removeAllListeners();

            // eventBus.removeListener(Events.APP_START, this.appStartHandler, this);
            // eventBus.removeListener(Events.LOGIN, this.startSyncJob, this);
            eventBus.removeListener(
                Events.FILE_UPLOADED,
                this.fileUploadedHandler,
                this
            );
            eventBus.removeListener(
                Events.LOCAL_FILES_UPDATED,
                this.debouncedFilesUpdated,
                this
            );

            await this.stopSyncJob();
        }
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
            await this.terminateLiveSyncWorker();
            await mlIDbStorage.clearMLDB();
        } catch (e) {
            logError(e, 'Failed in ML logout Handler');
        }
    }

    private async fileUploadedHandler(arg: {
        enteFile: EnteFile;
        localFile: globalThis.File;
    }) {
        if (!this.mlSearchEnabled) {
            return;
        }
        console.log('fileUploadedHandler: ', arg.enteFile.id);
        if (arg.enteFile.metadata.fileType !== FILE_TYPE.IMAGE) {
            console.log('Skipping non image file for local file processing');
            return;
        }
        try {
            await this.syncLocalFile(arg.enteFile, arg.localFile);
        } catch (error) {
            console.error('Error in syncLocalFile: ', arg.enteFile.id, error);
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
            this.liveSyncWorker = new MLWorkerWithProxy('ml-sync-live');
        }

        return this.liveSyncWorker.proxy;
    }

    private async terminateLiveSyncWorker() {
        if (!this.liveSyncWorker) {
            return;
        }
        try {
            const liveSyncWorker = await this.liveSyncWorker.proxy;
            await liveSyncWorker.closeLocalSyncContext();
        } catch (error) {
            console.error(
                'Error while closing local sync context, terminating worker',
                error
            );
        }
        this.liveSyncWorker?.terminate();
        this.liveSyncWorker = undefined;
    }

    private async onLiveSyncIdle() {
        console.log('Live sync idle');
        await this.terminateLiveSyncWorker();
        this.mlSearchEnabled && this.startSyncJob();
    }

    public async syncLocalFile(enteFile: EnteFile, localFile: globalThis.File) {
        const result = await this.liveSyncQueue.add(async () => {
            this.stopSyncJob();
            const token = getToken();
            const mlWorker = await this.getLiveSyncWorker();
            return mlWorker.syncLocalFile(token, enteFile, localFile);
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
            this.syncJobWorker = new MLWorkerWithProxy('ml-sync-job');
        }

        return this.syncJobWorker.proxy;
    }

    private terminateSyncJobWorker() {
        this.syncJobWorker?.terminate();
        this.syncJobWorker = undefined;
    }

    private async runMLSyncJob(): Promise<MLSyncJobResult> {
        // TODO: skipping is not required if we are caching chunks through service worker
        // currently worker chunk itself is not loaded when network is not there
        if (!navigator.onLine) {
            console.log(
                'Skipping ml-sync job run as not connected to internet.'
            );
            return {
                shouldBackoff: true,
                mlSyncResult: undefined,
            };
        }

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
            if (!this.mlSearchEnabled) {
                console.log('ML Search disabled, not starting ml sync job');
                return;
            }
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
            this.mlSyncJob?.stop();
            terminateWorker && this.terminateSyncJobWorker();
        } catch (e) {
            logError(e, 'Failed to stop MLSync Job');
        }
    }
}

export default new MLWorkManager();
