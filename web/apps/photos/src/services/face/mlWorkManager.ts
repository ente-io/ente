import { FILE_TYPE } from "@/media/file-type";
import { EnteFile } from "@/new/photos/types/file";
import { ensureElectron } from "@/next/electron";
import log from "@/next/log";
import { clientPackageNamePhotosDesktop } from "@/next/types/app";
import { ComlinkWorker } from "@/next/worker/comlink-worker";
import { eventBus, Events } from "@ente/shared/events";
import { getToken, getUserID } from "@ente/shared/storage/localStorage/helpers";
import debounce from "debounce";
import PQueue from "p-queue";
import type { DedicatedMLWorker } from "services/face/face.worker";

export type JobState = "Scheduled" | "Running" | "NotScheduled";

const createFaceWebWorker = () =>
    new Worker(new URL("face.worker.ts", import.meta.url));

const createFaceComlinkWorker = (name: string) =>
    new ComlinkWorker<typeof DedicatedMLWorker>(name, createFaceWebWorker());

export class MLSyncJob {
    private runCallback: () => Promise<boolean>;
    private state: JobState;
    private stopped: boolean;
    private intervalSec: number;
    private nextTimeoutId: ReturnType<typeof setTimeout>;

    constructor(runCallback: () => Promise<boolean>) {
        this.runCallback = runCallback;
        this.state = "NotScheduled";
        this.stopped = true;
        this.resetInterval();
    }

    public resetInterval() {
        this.intervalSec = 5;
    }

    public start() {
        this.stopped = false;
        this.resetInterval();
        if (this.state !== "Running") {
            this.scheduleNext();
        } else {
            log.info("Job already running, not scheduling");
        }
    }

    private scheduleNext() {
        if (this.state === "Scheduled" || this.nextTimeoutId) {
            this.clearScheduled();
        }

        this.nextTimeoutId = setTimeout(
            () => this.run(),
            this.intervalSec * 1000,
        );
        this.state = "Scheduled";
        log.info("Scheduled next job after: ", this.intervalSec);
    }

    async run() {
        this.nextTimeoutId = undefined;
        this.state = "Running";

        try {
            if (await this.runCallback()) {
                this.resetInterval();
            } else {
                this.intervalSec = Math.min(960, this.intervalSec * 2);
            }
        } catch (e) {
            console.error("Error while running Job: ", e);
        } finally {
            this.state = "NotScheduled";
            !this.stopped && this.scheduleNext();
        }
    }

    // currently client is responsible to terminate running job
    public stop() {
        this.stopped = true;
        this.clearScheduled();
    }

    private clearScheduled() {
        clearTimeout(this.nextTimeoutId);
        this.nextTimeoutId = undefined;
        this.state = "NotScheduled";
        log.info("Cleared next job");
    }
}

class MLWorkManager {
    private mlSyncJob: MLSyncJob;
    private syncJobWorker: ComlinkWorker<typeof DedicatedMLWorker>;

    private debouncedLiveSyncIdle: () => void;
    private debouncedFilesUpdated: () => void;

    private liveSyncQueue: PQueue;
    private liveSyncWorker: ComlinkWorker<typeof DedicatedMLWorker>;
    private mlSearchEnabled: boolean;

    public isSyncing = false;

    constructor() {
        this.liveSyncQueue = new PQueue({
            concurrency: 1,
            // TODO: temp, remove
            timeout: 300 * 1000,
            throwOnTimeout: true,
        });
        this.mlSearchEnabled = false;

        this.debouncedLiveSyncIdle = debounce(
            () => this.onLiveSyncIdle(),
            30 * 1000,
        );
        this.debouncedFilesUpdated = debounce(
            () => this.mlSearchEnabled && this.localFilesUpdatedHandler(),
            30 * 1000,
        );
    }

    public isMlSearchEnabled() {
        return this.mlSearchEnabled;
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

    async logout() {
        this.setMlSearchEnabled(false);
        this.stopSyncJob();
        this.mlSyncJob = undefined;
        await this.terminateLiveSyncWorker();
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
            this.liveSyncWorker = createFaceComlinkWorker("ml-sync-live");
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

    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    public async syncLocalFile(enteFile: EnteFile, localFile: globalThis.File) {
        return;
        /*
        TODO-ML(MR): Disable live sync for now
        await this.liveSyncQueue.add(async () => {
            this.stopSyncJob();
            const token = getToken();
            const userID = getUserID();
            const userAgent = await getUserAgent();
            const mlWorker = await this.getLiveSyncWorker();
            return mlWorker.syncLocalFile(
                token,
                userID,
                userAgent,
                enteFile,
                localFile,
            );
        });
        */
    }

    // Sync Job
    private async getSyncJobWorker() {
        if (!this.syncJobWorker) {
            this.syncJobWorker = createFaceComlinkWorker("ml-sync-job");
        }

        return await this.syncJobWorker.remote;
    }

    private terminateSyncJobWorker() {
        this.syncJobWorker?.terminate();
        this.syncJobWorker = undefined;
    }

    /**
     * Returns `false` to indicate that either an error occurred, or there are
     * not more files to process, or that we cannot currently process files.
     *
     * Which means that when it returns true, all is well and there are more
     * things pending to process, so we should chug along at full speed.
     */
    private async runMLSyncJob(): Promise<boolean> {
        this.isSyncing = true;
        try {
            // TODO: skipping is not required if we are caching chunks through service worker
            // currently worker chunk itself is not loaded when network is not there
            if (!navigator.onLine) {
                log.info(
                    "Skipping ml-sync job run as not connected to internet.",
                );
                return false;
            }

            const token = getToken();
            const userID = getUserID();
            const userAgent = await getUserAgent();
            const jobWorkerProxy = await this.getSyncJobWorker();

            return await jobWorkerProxy.sync(token, userID, userAgent);
            // this.terminateSyncJobWorker();
            // TODO: redirect/refresh to gallery in case of session_expired, stop ml sync job
        } catch (e) {
            log.error("Failed to run MLSync Job", e);
        } finally {
            this.isSyncing = false;
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
            if (!this.mlSyncJob) {
                this.mlSyncJob = new MLSyncJob(() => this.runMLSyncJob());
            }
            this.mlSyncJob.start();
        } catch (e) {
            log.error("Failed to start MLSync Job", e);
        }
    }

    public stopSyncJob() {
        try {
            log.info("MLWorkManager.stopSyncJob");
            this.mlSyncJob?.stop();
            this.terminateSyncJobWorker();
        } catch (e) {
            log.error("Failed to stop MLSync Job", e);
        }
    }
}

export default new MLWorkManager();

export function logQueueStats(queue: PQueue, name: string) {
    queue.on("active", () =>
        log.info(
            `queuestats: ${name}: Active, Size: ${queue.size} Pending: ${queue.pending}`,
        ),
    );
    queue.on("idle", () => log.info(`queuestats: ${name}: Idle`));
    queue.on("error", (error) =>
        console.error(`queuestats: ${name}: Error, `, error),
    );
}

const getUserAgent = async () => {
    const electron = ensureElectron();
    const name = clientPackageNamePhotosDesktop;
    const version = await electron.appVersion();
    return `${name}/${version}`;
};
