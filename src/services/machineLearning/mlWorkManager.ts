import { Remote } from 'comlink';
import PQueue from 'p-queue';
import { eventBus, Events } from 'services/events';
import { File } from 'services/fileService';
import {
    FACE_CROPS_CACHE_NAME,
    MachineLearningWorker,
    MLSyncConfig,
} from 'types/machineLearning';
import { getToken } from 'utils/common/key';
import { migrateFaceInterfaceUpdate } from 'utils/machineLearning/migrations';
import { getDedicatedMLWorker } from 'utils/machineLearning/worker';
import { logError } from 'utils/sentry';
import { getData, LS_KEYS } from 'utils/storage/localStorage';
import mlIDbStorage from 'utils/storage/mlIDbStorage';
import MLSyncJob from './mlSyncJob';

class MLWorkManager {
    private mlWorker: Promise<Remote<MachineLearningWorker>>;
    private mlSyncJob: MLSyncJob;
    private liveSyncQueue: PQueue;

    constructor() {
        this.mlSyncJob = new MLSyncJob();
        this.liveSyncQueue = new PQueue({ concurrency: 1 });

        this.liveSyncQueue.on('active', this.stopSyncJob, this);

        this.liveSyncQueue.on('idle', this.startSyncJob, this);

        eventBus.on(Events.APP_START, this.appStartHandler, this);

        eventBus.on(Events.LOGIN, this.startSyncJob, this);

        eventBus.on(Events.LOGOUT, this.logoutHandler, this);

        eventBus.on(Events.FILE_UPLOADED, this.fileUploadedHandler, this);

        eventBus.on(Events.LOCAL_FILES_UPDATED, this.startSyncJob, this);
    }

    private async appStartHandler() {
        try {
            const user = getData(LS_KEYS.USER);
            if (user?.token) {
                await migrateFaceInterfaceUpdate();
                this.startSyncJob();
            }
        } catch (e) {
            logError(e, 'Failed in ML appStart Handler');
        }
    }

    private async logoutHandler() {
        try {
            await this.stopSyncJob();
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
        try {
            await this.syncLocalFile(arg.enteFile, arg.localFile);
        } catch (e) {
            // console.error(e);
            logError(e, 'Failed in ML fileUploaded Handler');
        }
    }

    private async getMLWorker() {
        if (!this.mlWorker) {
            const MLWorker = getDedicatedMLWorker();
            // TODO: handle worker getting killed
            this.mlWorker = new MLWorker.comlink();
        }

        return this.mlWorker;
    }

    public async syncLocalFile(
        enteFile: File,
        localFile: globalThis.File,
        config?: MLSyncConfig
    ) {
        return this.liveSyncQueue.add(async () => {
            const token = await getToken();
            const mlWorker = await this.getMLWorker();
            return mlWorker.syncLocalFile(token, enteFile, localFile, config);
        });
    }

    public async startSyncJob() {
        try {
            console.log('MLWorkManager.startSyncJob');
            await this.mlSyncJob.resetInterval();
            const token = await getToken();
            const mlWorker = await this.getMLWorker();
            // TODO: handle case where job is currently running
            return this.mlSyncJob.start(token, mlWorker);
        } catch (e) {
            logError(e, 'Failed to start MLSync Job');
        }
    }

    public async stopSyncJob() {
        try {
            console.log('MLWorkManager.stopSyncJob');
            return this.mlSyncJob.stop();
        } catch (e) {
            logError(e, 'Failed to stop MLSync Job');
        }
    }
}

export default new MLWorkManager();
