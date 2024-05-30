import log from "@/next/log";
import { CustomError, parseUploadErrorCodes } from "@ente/shared/error";
import PQueue from "p-queue";
import mlIDbStorage, {
    type MinimalPersistedFileData,
} from "services/face/db-old";
import { syncLocalFiles } from "services/face/indexer";
import { FaceIndexerWorker } from "services/face/indexer.worker";
import { getLocalFiles } from "services/fileService";
import { EnteFile } from "types/file";

export const defaultMLVersion = 1;

const batchSize = 200;

export const MAX_ML_SYNC_ERROR_COUNT = 1;

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

    public isSyncing = false;

    public async sync(
        token: string,
        userID: number,
        userAgent: string,
    ): Promise<boolean> {
        if (!token) {
            throw Error("Token needed by ml service to sync file");
        }

        const syncContext = await this.getSyncContext(token, userID, userAgent);

        const localFiles = await syncLocalFiles(userID);
        syncContext.localFilesMap = localFiles;

        await this.getOutOfSyncFiles(syncContext);

        if (syncContext.outOfSyncFiles.length > 0) {
            await this.syncFiles(syncContext);
        }

        const error = syncContext.error;
        const nOutOfSyncFiles = syncContext.outOfSyncFiles.length;
        return !error && nOutOfSyncFiles > 0;
    }

    private newMlData(fileID: number) {
        return {
            fileID,
            mlVersion: 0,
            errorCount: 0,
        } as MinimalPersistedFileData;
    }

    private async getLocalFilesMap(syncContext: MLSyncContext) {
        if (!syncContext.localFilesMap) {
            const localFiles = await getLocalFiles();

            const personalFiles = localFiles.filter(
                (f) => f.ownerID === syncContext.userID,
            );
            syncContext.localFilesMap = new Map<number, EnteFile>();
            personalFiles.forEach((f) =>
                syncContext.localFilesMap.set(f.id, f),
            );
        }

        return syncContext.localFilesMap;
    }

    private async getOutOfSyncFiles(syncContext: MLSyncContext) {
        const startTime = Date.now();
        const fileIds = await mlIDbStorage.getFileIds(
            batchSize,
            defaultMLVersion,
            MAX_ML_SYNC_ERROR_COUNT,
        );

        log.info("fileIds: ", JSON.stringify(fileIds));

        const localFilesMap = await this.getLocalFilesMap(syncContext);
        syncContext.outOfSyncFiles = fileIds.map((fileId) =>
            localFilesMap.get(fileId),
        );
        log.info("getOutOfSyncFiles", Date.now() - startTime, "ms");
    }

    private async syncFiles(syncContext: MLSyncContext) {
        this.isSyncing = true;
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
        this.isSyncing = false;

        // TODO: In case syncJob has to use multiple ml workers
        // do in same transaction with each file update
        // or keep in files store itself
        await mlIDbStorage.incrementIndexVersion("files");
        // await this.disposeMLModels();
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
        token: string,
        userID: number,
        userAgent: string,
        enteFile: EnteFile,
        localFile?: globalThis.File,
    ) {
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
            log.error("ML syncFile failed", e);
            let error = e;
            console.error(
                "Error in ml sync, fileId: ",
                enteFile.id,
                "name: ",
                enteFile.metadata.title,
                error,
            );
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

            await this.persistMLFileSyncError(enteFile, error);
            syncContext.nSyncedFiles += 1;
        }
    }

    private async syncFile(
        enteFile: EnteFile,
        localFile: globalThis.File | undefined,
        userAgent: string,
    ) {
        const oldMlFile = await mlIDbStorage.getFile(enteFile.id);
        if (oldMlFile && oldMlFile.mlVersion) {
            return;
        }

        const worker = new FaceIndexerWorker();

        const newMlFile = await worker.index(enteFile, localFile, userAgent);
        await mlIDbStorage.putFile(newMlFile);
    }

    private async persistMLFileSyncError(enteFile: EnteFile, e: Error) {
        try {
            await mlIDbStorage.upsertFileInTx(enteFile.id, (mlFileData) => {
                if (!mlFileData) {
                    mlFileData = this.newMlData(enteFile.id);
                }
                mlFileData.errorCount = (mlFileData.errorCount || 0) + 1;
                console.error(`lastError for ${enteFile.id}`, e);

                return mlFileData;
            });
        } catch (e) {
            // TODO: logError or stop sync job after most of the requests are failed
            console.error("Error while storing ml sync error", e);
        }
    }
}

export default new MachineLearningService();
