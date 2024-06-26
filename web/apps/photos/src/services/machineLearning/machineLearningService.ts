import { EnteFile } from "@/new/photos/types/file";
import log from "@/next/log";
import { CustomError, parseUploadErrorCodes } from "@ente/shared/error";
import PQueue from "p-queue";
import { syncAndGetFilesToIndex } from "services/face/indexer";
import { FaceIndexerWorker } from "services/face/indexer.worker";

const batchSize = 200;

class MLSyncContext {
    public token: string;
    public userID: number;
    public userAgent: string;

    public localFilesMap: Map<number, EnteFile>;
    public outOfSyncFiles: EnteFile[];
    public nSyncedFiles: number;
    public error?: Error;

    public syncQueue: PQueue;

    constructor(token: string, userID: number, userAgent: string) {
        this.token = token;
        this.userID = userID;
        this.userAgent = userAgent;

        this.outOfSyncFiles = [];
        this.nSyncedFiles = 0;

        const concurrency = getConcurrency();
        this.syncQueue = new PQueue({ concurrency });
    }

    public async dispose() {
        this.localFilesMap = undefined;
        await this.syncQueue.onIdle();
        this.syncQueue.removeAllListeners();
    }
}

const getConcurrency = () =>
    Math.max(2, Math.ceil(navigator.hardwareConcurrency / 2));

class MachineLearningService {
    private localSyncContext: Promise<MLSyncContext>;
    private syncContext: Promise<MLSyncContext>;

    public async sync(
        token: string,
        userID: number,
        userAgent: string,
    ): Promise<boolean> {
        if (!token) {
            throw Error("Token needed by ml service to sync file");
        }

        const syncContext = await this.getSyncContext(token, userID, userAgent);

        syncContext.outOfSyncFiles = await syncAndGetFilesToIndex(
            userID,
            batchSize,
        );

        if (syncContext.outOfSyncFiles.length > 0) {
            await this.syncFiles(syncContext);
        }

        const error = syncContext.error;
        const nOutOfSyncFiles = syncContext.outOfSyncFiles.length;
        return !error && nOutOfSyncFiles > 0;
    }

    private async syncFiles(syncContext: MLSyncContext) {
        try {
            const functions = syncContext.outOfSyncFiles.map(
                (outOfSyncfile) => async () => {
                    await this.syncFileWithErrorHandler(
                        syncContext,
                        outOfSyncfile,
                    );
                    // TODO: just store file and faces count in syncContext
                },
            );
            syncContext.syncQueue.on("error", () => {
                syncContext.syncQueue.clear();
            });
            await syncContext.syncQueue.addAll(functions);
        } catch (error) {
            console.error("Error in sync job: ", error);
            syncContext.error = error;
        }
        await syncContext.syncQueue.onIdle();
    }

    private async getSyncContext(
        token: string,
        userID: number,
        userAgent: string,
    ) {
        if (!this.syncContext) {
            log.info("Creating syncContext");

            // TODO-ML(MR): Keep as promise for now.
            this.syncContext = new Promise((resolve) => {
                resolve(new MLSyncContext(token, userID, userAgent));
            });
        } else {
            log.info("reusing existing syncContext");
        }
        return this.syncContext;
    }

    private async getLocalSyncContext(
        token: string,
        userID: number,
        userAgent: string,
    ) {
        // TODO-ML(MR): This is updating the file ML version. verify.
        if (!this.localSyncContext) {
            log.info("Creating localSyncContext");
            // TODO-ML(MR):
            this.localSyncContext = new Promise((resolve) => {
                resolve(new MLSyncContext(token, userID, userAgent));
            });
        } else {
            log.info("reusing existing localSyncContext");
        }
        return this.localSyncContext;
    }

    public async closeLocalSyncContext() {
        if (this.localSyncContext) {
            log.info("Closing localSyncContext");
            const syncContext = await this.localSyncContext;
            await syncContext.dispose();
            this.localSyncContext = undefined;
        }
    }

    public async syncLocalFile(
        // eslint-disable-next-line @typescript-eslint/no-unused-vars
        token: string,
        // eslint-disable-next-line @typescript-eslint/no-unused-vars
        userID: number,
        // eslint-disable-next-line @typescript-eslint/no-unused-vars
        userAgent: string,
        // eslint-disable-next-line @typescript-eslint/no-unused-vars
        enteFile: EnteFile,
        // eslint-disable-next-line @typescript-eslint/no-unused-vars
        localFile?: globalThis.File,
    ) {
        /* TODO-ML(MR): Currently not used
        const syncContext = await this.getLocalSyncContext(
            token,
            userID,
            userAgent,
        );

        try {
            await this.syncFileWithErrorHandler(
                syncContext,
                enteFile,
                localFile,
            );

            if (syncContext.nSyncedFiles >= batchSize) {
                await this.closeLocalSyncContext();
            }
            // await syncContext.dispose();
        } catch (e) {
            console.error("Error while syncing local file: ", enteFile.id, e);
        }
        */
    }

    private async syncFileWithErrorHandler(
        syncContext: MLSyncContext,
        enteFile: EnteFile,
        localFile?: globalThis.File,
    ) {
        try {
            await this.syncFile(enteFile, localFile, syncContext.userAgent);
            syncContext.nSyncedFiles += 1;
        } catch (e) {
            let error = e;
            if ("status" in error) {
                const parsedMessage = parseUploadErrorCodes(error);
                error = parsedMessage;
            }
            // TODO: throw errors not related to specific file
            // sync job run should stop after these errors
            // don't persist these errors against file,
            // can include indexeddb/cache errors too
            switch (error.message) {
                case CustomError.SESSION_EXPIRED:
                case CustomError.NETWORK_ERROR:
                    throw error;
            }

            syncContext.nSyncedFiles += 1;
        }
    }

    private async syncFile(
        enteFile: EnteFile,
        file: File | undefined,
        userAgent: string,
    ) {
        const worker = new FaceIndexerWorker();

        await worker.index(enteFile, file, userAgent);
    }
}

export default new MachineLearningService();
