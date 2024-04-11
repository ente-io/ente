import log from "@/next/log";
import { ComlinkWorker } from "@/next/worker/comlink-worker";
import { eventBus, Events } from "@ente/shared/events";
import { getToken, getUserID } from "@ente/shared/storage/localStorage/helpers";
import { FILE_TYPE } from "constants/file";
import debounce from "debounce";
import PQueue from "p-queue";
import { JobResult } from "types/common/job";
import { EnteFile } from "types/file";
import { MLSyncResult } from "types/machineLearning";
import { getDedicatedMLWorker } from "utils/comlink/ComlinkMLWorker";
import { SimpleJob } from "utils/common/job";
import { logQueueStats } from "utils/machineLearning";
import { getMLSyncJobConfig } from "utils/machineLearning/config";
import mlIDbStorage from "utils/storage/mlIDbStorage";
import { DedicatedMLWorker } from "worker/ml.worker";

const LIVE_SYNC_IDLE_DEBOUNCE_SEC = 30;
const LIVE_SYNC_QUEUE_TIMEOUT_SEC = 300;
const LOCAL_FILES_UPDATED_DEBOUNCE_SEC = 30;

export interface MLSyncJobResult extends JobResult {
    mlSyncResult: MLSyncResult;
}

export class MLSyncJob extends SimpleJob<MLSyncJobResult> {}

class MLWorkManager {
    private mlSyncJob: MLSyncJob;
    private syncJobWorker: ComlinkWorker<typeof DedicatedMLWorker>;

    private debouncedLiveSyncIdle: () => void;
    private debouncedFilesUpdated: () => void;

    private liveSyncQueue: PQueue;
    private liveSyncWorker: ComlinkWorker<typeof DedicatedMLWorker>;
    private mlSearchEnabled: boolean;

    constructor() {
        this.liveSyncQueue = new PQueue({
            concurrency: 1,
            // TODO: temp, remove
            timeout: LIVE_SYNC_QUEUE_TIMEOUT_SEC * 1000,
            throwOnTimeout: true,
        });
        this.mlSearchEnabled = false;

        eventBus.on(Events.LOGOUT, this.logoutHandler.bind(this), this);
        this.debouncedLiveSyncIdle = debounce(
            () => this.onLiveSyncIdle(),
            LIVE_SYNC_IDLE_DEBOUNCE_SEC * 1000,
        );
        this.debouncedFilesUpdated = debounce(
            () => this.mlSearchEnabled && this.localFilesUpdatedHandler(),
            LOCAL_FILES_UPDATED_DEBOUNCE_SEC * 1000,
        );
    }

    public async setMlSearchEnabled(enabled: boolean) {
        if (!this.mlSearchEnabled && enabled) {
            log.info("Enabling MLWorkManager");
            this.mlSearchEnabled = true;

            logQueueStats(this.liveSyncQueue, "livesync");
            this.liveSyncQueue.on("idle", this.debouncedLiveSyncIdle, this);

            eventBus.on(
                Events.FILE_UPLOADED,
                this.fileUploadedHandler.bind(this),
                this,
            );
            eventBus.on(
                Events.LOCAL_FILES_UPDATED,
                this.debouncedFilesUpdated,
                this,
            );

            await this.startSyncJob();
        } else if (this.mlSearchEnabled && !enabled) {
            log.info("Disabling MLWorkManager");
            this.mlSearchEnabled = false;

            this.liveSyncQueue.removeAllListeners();

            eventBus.removeListener(
                Events.FILE_UPLOADED,
                this.fileUploadedHandler.bind(this),
                this,
            );
            eventBus.removeListener(
                Events.LOCAL_FILES_UPDATED,
                this.debouncedFilesUpdated,
                this,
            );

            this.stopSyncJob();
        }
    }

    // Handlers
    private async appStartHandler() {
        log.info("appStartHandler");
        try {
            this.startSyncJob();
        } catch (e) {
            log.error("Failed in ML appStart Handler", e);
        }
    }

    private async logoutHandler() {
        log.info("logoutHandler");
        try {
            this.stopSyncJob();
            this.mlSyncJob = undefined;
            await this.terminateLiveSyncWorker();
            await mlIDbStorage.clearMLDB();
        } catch (e) {
            log.error("Failed in ML logout Handler", e);
        }
    }

    private async fileUploadedHandler(arg: {
        enteFile: EnteFile;
        localFile: globalThis.File;
    }) {
        if (!this.mlSearchEnabled) {
            return;
        }
        log.info("fileUploadedHandler: ", arg.enteFile.id);
        if (arg.enteFile.metadata.fileType !== FILE_TYPE.IMAGE) {
            log.info("Skipping non image file for local file processing");
            return;
        }
        try {
            await this.syncLocalFile(arg.enteFile, arg.localFile);
        } catch (error) {
            console.error("Error in syncLocalFile: ", arg.enteFile.id, error);
            this.liveSyncQueue.clear();
            // logError(e, 'Failed in ML fileUploaded Handler');
        }
    }

    private async localFilesUpdatedHandler() {
        log.info("Local files updated");
        this.startSyncJob();
    }

    // Live Sync
    private async getLiveSyncWorker() {
        if (!this.liveSyncWorker) {
            this.liveSyncWorker = getDedicatedMLWorker("ml-sync-live");
        }

        return await this.liveSyncWorker.remote;
    }

    private async terminateLiveSyncWorker() {
        if (!this.liveSyncWorker) {
            return;
        }
        try {
            const liveSyncWorker = await this.liveSyncWorker.remote;
            await liveSyncWorker.closeLocalSyncContext();
        } catch (error) {
            console.error(
                "Error while closing local sync context, terminating worker",
                error,
            );
        }
        this.liveSyncWorker?.terminate();
        this.liveSyncWorker = undefined;
    }

    private async onLiveSyncIdle() {
        log.info("Live sync idle");
        await this.terminateLiveSyncWorker();
        this.mlSearchEnabled && this.startSyncJob();
    }

    public async syncLocalFile(enteFile: EnteFile, localFile: globalThis.File) {
        const result = await this.liveSyncQueue.add(async () => {
            this.stopSyncJob();
            const token = getToken();
            const userID = getUserID();
            const mlWorker = await this.getLiveSyncWorker();
            return mlWorker.syncLocalFile(token, userID, enteFile, localFile);
        });

        if (result instanceof Error) {
            // TODO: redirect/refresh to gallery in case of session_expired
            // may not be required as uploader should anyways take care of this
            console.error("Error while syncing local file: ", result);
        }
    }

    // Sync Job
    private async getSyncJobWorker() {
        if (!this.syncJobWorker) {
            this.syncJobWorker = getDedicatedMLWorker("ml-sync-job");
        }

        return await this.syncJobWorker.remote;
    }

    private terminateSyncJobWorker() {
        this.syncJobWorker?.terminate();
        this.syncJobWorker = undefined;
    }

    private async runMLSyncJob(): Promise<MLSyncJobResult> {
        try {
            // TODO: skipping is not required if we are caching chunks through service worker
            // currently worker chunk itself is not loaded when network is not there
            if (!navigator.onLine) {
                log.info(
                    "Skipping ml-sync job run as not connected to internet.",
                );
                return {
                    shouldBackoff: true,
                    mlSyncResult: undefined,
                };
            }

            const token = getToken();
            const userID = getUserID();
            const jobWorkerProxy = await this.getSyncJobWorker();

            const mlSyncResult = await jobWorkerProxy.sync(token, userID);

            // this.terminateSyncJobWorker();
            const jobResult: MLSyncJobResult = {
                shouldBackoff:
                    !!mlSyncResult.error || mlSyncResult.nOutOfSyncFiles < 1,
                mlSyncResult,
            };
            log.info("ML Sync Job result: ", JSON.stringify(jobResult));

            // TODO: redirect/refresh to gallery in case of session_expired, stop ml sync job

            return jobResult;
        } catch (e) {
            log.error("Failed to run MLSync Job", e);
        }
    }

    public async startSyncJob() {
        try {
            log.info("MLWorkManager.startSyncJob");
            if (!this.mlSearchEnabled) {
                log.info("ML Search disabled, not starting ml sync job");
                return;
            }
            if (!getToken()) {
                log.info("User not logged in, not starting ml sync job");
                return;
            }
            const mlSyncJobConfig = await getMLSyncJobConfig();
            if (!this.mlSyncJob) {
                this.mlSyncJob = new MLSyncJob(mlSyncJobConfig, () =>
                    this.runMLSyncJob(),
                );
            }
            this.mlSyncJob.start();
        } catch (e) {
            log.error("Failed to start MLSync Job", e);
        }
    }

    public stopSyncJob(terminateWorker: boolean = true) {
        try {
            log.info("MLWorkManager.stopSyncJob");
            this.mlSyncJob?.stop();
            terminateWorker && this.terminateSyncJobWorker();
        } catch (e) {
            log.error("Failed to stop MLSync Job", e);
        }
    }
}

export default new MLWorkManager();
