import { ensureElectron } from "@/next/electron";
import log from "@/next/log";
import { CustomError } from "@ente/shared/error";
import { Events, eventBus } from "@ente/shared/events";
import { LS_KEYS, getData, setData } from "@ente/shared/storage/localStorage";
import { User } from "@ente/shared/user/types";
import { sleep } from "@ente/shared/utils";
import QueueProcessor, {
    CancellationStatus,
    RequestCanceller,
} from "@ente/shared/utils/queueProcessor";
import { ExportStage } from "constants/export";
import { FILE_TYPE } from "constants/file";
import { Collection } from "types/collection";
import {
    ExportProgress,
    ExportRecord,
    ExportSettings,
    ExportUIUpdaters,
} from "types/export";
import { EnteFile } from "types/file";
import {
    constructCollectionNameMap,
    getCollectionUserFacingName,
    getNonEmptyPersonalCollections,
} from "utils/collection";
import {
    convertCollectionIDExportNameObjectToMap,
    convertFileIDExportNameObjectToMap,
    getCollectionExportPath,
    getCollectionExportedFiles,
    getCollectionIDFromFileUID,
    getDeletedExportedCollections,
    getDeletedExportedFiles,
    getExportRecordFileUID,
    getFileExportPath,
    getFileMetadataExportPath,
    getGoogleLikeMetadataFile,
    getLivePhotoExportName,
    getMetadataFileExportPath,
    getMetadataFolderExportPath,
    getRenamedExportedCollections,
    getTrashedFileExportPath,
    getUnExportedFiles,
    getUniqueCollectionExportName,
    getUniqueFileExportName,
    isLivePhotoExportName,
    parseLivePhotoExportName,
} from "utils/export";
import {
    generateStreamFromArrayBuffer,
    getPersonalFiles,
    getUpdatedEXIFFileForDownload,
    mergeMetadata,
} from "utils/file";
import { getAllLocalCollections } from "../collectionService";
import downloadManager from "../download";
import { getAllLocalFiles } from "../fileService";
import { decodeLivePhoto } from "../livePhotoService";
import { migrateExport } from "./migration";

const EXPORT_RECORD_FILE_NAME = "export_status.json";

export const ENTE_EXPORT_DIRECTORY = "ente Photos";

export const NULL_EXPORT_RECORD: ExportRecord = {
    version: 3,
    lastAttemptTimestamp: null,
    stage: ExportStage.INIT,
    fileExportNames: {},
    collectionExportNames: {},
};

class ExportService {
    private exportSettings: ExportSettings;
    private exportInProgress: RequestCanceller = null;
    private reRunNeeded = false;
    private exportRecordUpdater = new QueueProcessor<ExportRecord>();
    private fileReader: FileReader = null;
    private continuousExportEventHandler: () => void;
    private uiUpdater: ExportUIUpdaters = {
        setExportProgress: () => {},
        setExportStage: () => {},
        setLastExportTime: () => {},
        setPendingExports: () => {},
    };
    private currentExportProgress: ExportProgress = {
        total: 0,
        success: 0,
        failed: 0,
    };

    getExportSettings(): ExportSettings {
        try {
            if (this.exportSettings) {
                return this.exportSettings;
            }
            const exportSettings = getData(LS_KEYS.EXPORT);
            this.exportSettings = exportSettings;
            return exportSettings;
        } catch (e) {
            log.error("getExportSettings failed", e);
            throw e;
        }
    }

    updateExportSettings(newData: Partial<ExportSettings>) {
        try {
            const exportSettings = this.getExportSettings();
            const newSettings = { ...exportSettings, ...newData };
            this.exportSettings = newSettings;
            setData(LS_KEYS.EXPORT, newSettings);
        } catch (e) {
            log.error("updateExportSettings failed", e);
            throw e;
        }
    }

    async runMigration(
        exportDir: string,
        exportRecord: ExportRecord,
        updateProgress: (progress: ExportProgress) => void,
    ) {
        try {
            log.info("running migration");
            await migrateExport(exportDir, exportRecord, updateProgress);
            log.info("migration completed");
        } catch (e) {
            log.error("migration failed", e);
            throw e;
        }
    }

    setUIUpdaters(uiUpdater: ExportUIUpdaters) {
        this.uiUpdater = uiUpdater;
        this.uiUpdater.setExportProgress(this.currentExportProgress);
    }

    private updateExportProgress(exportProgress: ExportProgress) {
        this.currentExportProgress = exportProgress;
        this.uiUpdater.setExportProgress(exportProgress);
    }

    private async updateExportStage(stage: ExportStage) {
        const exportFolder = this.getExportSettings()?.folder;
        await this.updateExportRecord(exportFolder, { stage });
        this.uiUpdater.setExportStage(stage);
    }

    private async updateLastExportTime(exportTime: number) {
        const exportFolder = this.getExportSettings()?.folder;
        await this.updateExportRecord(exportFolder, {
            lastAttemptTimestamp: exportTime,
        });
        this.uiUpdater.setLastExportTime(exportTime);
    }

    async changeExportDirectory() {
        try {
            const newRootDir = await ensureElectron().selectDirectory();
            if (!newRootDir) {
                throw Error(CustomError.SELECT_FOLDER_ABORTED);
            }
            const newExportDir = `${newRootDir}/${ENTE_EXPORT_DIRECTORY}`;
            await ensureElectron().checkExistsAndCreateDir(newExportDir);
            return newExportDir;
        } catch (e) {
            if (e.message !== CustomError.SELECT_FOLDER_ABORTED) {
                log.error("changeExportDirectory failed", e);
            }
            throw e;
        }
    }

    enableContinuousExport() {
        try {
            if (this.continuousExportEventHandler) {
                log.info("continuous export already enabled");
                return;
            }
            log.info("enabling continuous export");
            this.continuousExportEventHandler = () => {
                this.scheduleExport();
            };
            this.continuousExportEventHandler();
            eventBus.addListener(
                Events.LOCAL_FILES_UPDATED,
                this.continuousExportEventHandler,
            );
        } catch (e) {
            log.error("failed to enableContinuousExport ", e);
            throw e;
        }
    }

    disableContinuousExport() {
        try {
            if (!this.continuousExportEventHandler) {
                log.info("continuous export already disabled");
                return;
            }
            log.info("disabling continuous export");
            eventBus.removeListener(
                Events.LOCAL_FILES_UPDATED,
                this.continuousExportEventHandler,
            );
            this.continuousExportEventHandler = null;
        } catch (e) {
            log.error("failed to disableContinuousExport", e);
            throw e;
        }
    }

    getPendingExports = async (
        exportRecord: ExportRecord,
    ): Promise<EnteFile[]> => {
        try {
            const user: User = getData(LS_KEYS.USER);
            const files = await getAllLocalFiles();
            const collections = await getAllLocalCollections();
            const collectionIdToOwnerIDMap = new Map<number, number>(
                collections.map((collection) => [
                    collection.id,
                    collection.owner.id,
                ]),
            );
            const userPersonalFiles = getPersonalFiles(
                files,
                user,
                collectionIdToOwnerIDMap,
            );

            const unExportedFiles = getUnExportedFiles(
                userPersonalFiles,
                exportRecord,
            );
            return unExportedFiles;
        } catch (e) {
            log.error("getUpdateFileLists failed", e);
            throw e;
        }
    };

    async preExport(exportFolder: string) {
        await this.verifyExportFolderExists(exportFolder);
        const exportRecord = await this.getExportRecord(exportFolder);
        await this.updateExportStage(ExportStage.MIGRATION);
        await this.runMigration(
            exportFolder,
            exportRecord,
            this.updateExportProgress.bind(this),
        );
        await this.updateExportStage(ExportStage.STARTING);
    }

    async postExport() {
        try {
            const exportFolder = this.getExportSettings()?.folder;
            if (!(await this.exportFolderExists(exportFolder))) {
                this.uiUpdater.setExportStage(ExportStage.INIT);
                return;
            }
            await this.updateExportStage(ExportStage.FINISHED);
            await this.updateLastExportTime(Date.now());

            const exportRecord = await this.getExportRecord(exportFolder);

            const pendingExports = await this.getPendingExports(exportRecord);
            this.uiUpdater.setPendingExports(pendingExports);
        } catch (e) {
            log.error("postExport failed", e);
        }
    }

    async stopRunningExport() {
        try {
            log.info("user requested export cancellation");
            this.exportInProgress.exec();
            this.exportInProgress = null;
            this.reRunNeeded = false;
            await this.postExport();
        } catch (e) {
            log.error("stopRunningExport failed", e);
        }
    }

    scheduleExport = async () => {
        try {
            if (this.exportInProgress) {
                log.info("export in progress, scheduling re-run");
                this.reRunNeeded = true;
                return;
            } else {
                log.info("export not in progress, starting export");
            }

            const isCanceled: CancellationStatus = { status: false };
            const canceller: RequestCanceller = {
                exec: () => {
                    isCanceled.status = true;
                },
            };
            this.exportInProgress = canceller;
            try {
                const exportFolder = this.getExportSettings()?.folder;
                await this.preExport(exportFolder);
                log.info("export started");
                await this.runExport(exportFolder, isCanceled);
                log.info("export completed");
            } finally {
                if (isCanceled.status) {
                    log.info("export cancellation done");
                    if (!this.exportInProgress) {
                        await this.postExport();
                    }
                } else {
                    await this.postExport();
                    log.info("resetting export in progress after completion");
                    this.exportInProgress = null;
                    if (this.reRunNeeded) {
                        this.reRunNeeded = false;
                        log.info("re-running export");
                        setTimeout(() => this.scheduleExport(), 0);
                    }
                }
            }
        } catch (e) {
            if (
                e.message !== CustomError.EXPORT_FOLDER_DOES_NOT_EXIST &&
                e.message !== CustomError.EXPORT_STOPPED
            ) {
                log.error("scheduleExport failed", e);
            }
        }
    };

    private async runExport(
        exportFolder: string,
        isCanceled: CancellationStatus,
    ) {
        try {
            const user: User = getData(LS_KEYS.USER);
            const files = mergeMetadata(await getAllLocalFiles());
            const collections = await getAllLocalCollections();
            const collectionIdToOwnerIDMap = new Map<number, number>(
                collections.map((collection) => [
                    collection.id,
                    collection.owner.id,
                ]),
            );
            const personalFiles = getPersonalFiles(
                files,
                user,
                collectionIdToOwnerIDMap,
            );

            const nonEmptyPersonalCollections = getNonEmptyPersonalCollections(
                collections,
                personalFiles,
                user,
            );

            const exportRecord = await this.getExportRecord(exportFolder);
            const collectionIDExportNameMap =
                convertCollectionIDExportNameObjectToMap(
                    exportRecord.collectionExportNames,
                );
            const collectionIDNameMap = constructCollectionNameMap(
                nonEmptyPersonalCollections,
            );

            const renamedCollections = getRenamedExportedCollections(
                nonEmptyPersonalCollections,
                exportRecord,
            );

            const removedFileUIDs = getDeletedExportedFiles(
                personalFiles,
                exportRecord,
            );
            const filesToExport = getUnExportedFiles(
                personalFiles,
                exportRecord,
            );
            const deletedExportedCollections = getDeletedExportedCollections(
                nonEmptyPersonalCollections,
                exportRecord,
            );

            log.info(
                `personal files:${personalFiles.length} unexported files: ${filesToExport.length}, deleted exported files: ${removedFileUIDs.length}, renamed collections: ${renamedCollections.length}, deleted collections: ${deletedExportedCollections.length}`,
            );
            let success = 0;
            let failed = 0;
            this.uiUpdater.setExportProgress({
                success: success,
                failed: failed,
                total: filesToExport.length,
            });
            const incrementSuccess = () => {
                this.updateExportProgress({
                    success: ++success,
                    failed: failed,
                    total: filesToExport.length,
                });
            };
            const incrementFailed = () => {
                this.updateExportProgress({
                    success: success,
                    failed: ++failed,
                    total: filesToExport.length,
                });
            };
            if (renamedCollections?.length > 0) {
                this.updateExportStage(ExportStage.RENAMING_COLLECTION_FOLDERS);
                log.info(`renaming ${renamedCollections.length} collections`);
                await this.collectionRenamer(
                    exportFolder,
                    collectionIDExportNameMap,
                    renamedCollections,
                    isCanceled,
                );
            }

            if (removedFileUIDs?.length > 0) {
                this.updateExportStage(ExportStage.TRASHING_DELETED_FILES);
                log.info(`trashing ${removedFileUIDs.length} files`);
                await this.fileTrasher(
                    exportFolder,
                    collectionIDExportNameMap,
                    removedFileUIDs,
                    isCanceled,
                );
            }
            if (filesToExport?.length > 0) {
                this.updateExportStage(ExportStage.EXPORTING_FILES);
                log.info(`exporting ${filesToExport.length} files`);
                await this.fileExporter(
                    filesToExport,
                    collectionIDNameMap,
                    collectionIDExportNameMap,
                    exportFolder,
                    incrementSuccess,
                    incrementFailed,
                    isCanceled,
                );
            }
            if (deletedExportedCollections?.length > 0) {
                this.updateExportStage(
                    ExportStage.TRASHING_DELETED_COLLECTIONS,
                );
                log.info(
                    `removing ${deletedExportedCollections.length} collections`,
                );
                await this.collectionRemover(
                    deletedExportedCollections,
                    exportFolder,
                    isCanceled,
                );
            }
        } catch (e) {
            if (
                e.message !== CustomError.EXPORT_FOLDER_DOES_NOT_EXIST &&
                e.message !== CustomError.EXPORT_STOPPED
            ) {
                log.error("runExport failed", e);
            }
            throw e;
        }
    }

    async collectionRenamer(
        exportFolder: string,
        collectionIDExportNameMap: Map<number, string>,
        renamedCollections: Collection[],
        isCanceled: CancellationStatus,
    ) {
        try {
            for (const collection of renamedCollections) {
                try {
                    if (isCanceled.status) {
                        throw Error(CustomError.EXPORT_STOPPED);
                    }
                    await this.verifyExportFolderExists(exportFolder);
                    const oldCollectionExportName =
                        collectionIDExportNameMap.get(collection.id);
                    const oldCollectionExportPath = getCollectionExportPath(
                        exportFolder,
                        oldCollectionExportName,
                    );

                    const newCollectionExportName =
                        await getUniqueCollectionExportName(
                            exportFolder,
                            getCollectionUserFacingName(collection),
                        );
                    log.info(
                        `renaming collection with id ${collection.id} from ${oldCollectionExportName} to ${newCollectionExportName}`,
                    );
                    const newCollectionExportPath = getCollectionExportPath(
                        exportFolder,
                        newCollectionExportName,
                    );

                    await this.addCollectionExportedRecord(
                        exportFolder,
                        collection.id,
                        newCollectionExportName,
                    );
                    collectionIDExportNameMap.set(
                        collection.id,
                        newCollectionExportName,
                    );
                    try {
                        await ensureElectron().rename(
                            oldCollectionExportPath,
                            newCollectionExportPath,
                        );
                    } catch (e) {
                        await this.addCollectionExportedRecord(
                            exportFolder,
                            collection.id,
                            oldCollectionExportName,
                        );
                        collectionIDExportNameMap.set(
                            collection.id,
                            oldCollectionExportName,
                        );
                        throw e;
                    }
                    log.info(
                        `renaming collection with id ${collection.id} from ${oldCollectionExportName} to ${newCollectionExportName} successful`,
                    );
                } catch (e) {
                    log.error("collectionRenamer failed a collection", e);
                    if (
                        e.message ===
                            CustomError.UPDATE_EXPORTED_RECORD_FAILED ||
                        e.message ===
                            CustomError.EXPORT_FOLDER_DOES_NOT_EXIST ||
                        e.message === CustomError.EXPORT_STOPPED
                    ) {
                        throw e;
                    }
                }
            }
        } catch (e) {
            if (
                e.message !== CustomError.EXPORT_FOLDER_DOES_NOT_EXIST &&
                e.message !== CustomError.EXPORT_STOPPED
            ) {
                log.error("collectionRenamer failed", e);
            }
            throw e;
        }
    }

    async collectionRemover(
        deletedExportedCollectionIDs: number[],
        exportFolder: string,
        isCanceled: CancellationStatus,
    ) {
        try {
            const exportRecord = await this.getExportRecord(exportFolder);
            const collectionIDPathMap =
                convertCollectionIDExportNameObjectToMap(
                    exportRecord.collectionExportNames,
                );
            for (const collectionID of deletedExportedCollectionIDs) {
                try {
                    if (isCanceled.status) {
                        throw Error(CustomError.EXPORT_STOPPED);
                    }
                    await this.verifyExportFolderExists(exportFolder);
                    log.info(
                        `removing collection with id ${collectionID} from export folder`,
                    );
                    const collectionExportName =
                        collectionIDPathMap.get(collectionID);
                    // verify that the all exported files from the collection has been removed
                    const collectionExportedFiles = getCollectionExportedFiles(
                        exportRecord,
                        collectionID,
                    );
                    if (collectionExportedFiles.length > 0) {
                        throw new Error(
                            "collection is not empty, can't remove",
                        );
                    }
                    const collectionExportPath = getCollectionExportPath(
                        exportFolder,
                        collectionExportName,
                    );
                    await this.removeCollectionExportedRecord(
                        exportFolder,
                        collectionID,
                    );
                    try {
                        // delete the collection metadata folder
                        await ensureElectron().deleteFolder(
                            getMetadataFolderExportPath(collectionExportPath),
                        );
                        // delete the collection folder
                        await ensureElectron().deleteFolder(
                            collectionExportPath,
                        );
                    } catch (e) {
                        await this.addCollectionExportedRecord(
                            exportFolder,
                            collectionID,
                            collectionExportName,
                        );
                        throw e;
                    }
                    log.info(
                        `removing collection with id ${collectionID} from export folder successful`,
                    );
                } catch (e) {
                    log.error("collectionRemover failed a collection", e);
                    if (
                        e.message ===
                            CustomError.UPDATE_EXPORTED_RECORD_FAILED ||
                        e.message ===
                            CustomError.EXPORT_FOLDER_DOES_NOT_EXIST ||
                        e.message === CustomError.EXPORT_STOPPED
                    ) {
                        throw e;
                    }
                }
            }
        } catch (e) {
            if (
                e.message !== CustomError.EXPORT_FOLDER_DOES_NOT_EXIST &&
                e.message !== CustomError.EXPORT_STOPPED
            ) {
                log.error("collectionRemover failed", e);
            }
            throw e;
        }
    }

    async fileExporter(
        files: EnteFile[],
        collectionIDNameMap: Map<number, string>,
        collectionIDFolderNameMap: Map<number, string>,
        exportDir: string,
        incrementSuccess: () => void,
        incrementFailed: () => void,
        isCanceled: CancellationStatus,
    ): Promise<void> {
        try {
            for (const file of files) {
                log.info(
                    `exporting file ${file.metadata.title} with id ${
                        file.id
                    } from collection ${collectionIDNameMap.get(
                        file.collectionID,
                    )}`,
                );
                if (isCanceled.status) {
                    throw Error(CustomError.EXPORT_STOPPED);
                }
                try {
                    await this.verifyExportFolderExists(exportDir);
                    let collectionExportName = collectionIDFolderNameMap.get(
                        file.collectionID,
                    );
                    if (!collectionExportName) {
                        collectionExportName =
                            await this.createNewCollectionExport(
                                exportDir,
                                file.collectionID,
                                collectionIDNameMap,
                            );
                        await this.addCollectionExportedRecord(
                            exportDir,
                            file.collectionID,
                            collectionExportName,
                        );
                        collectionIDFolderNameMap.set(
                            file.collectionID,
                            collectionExportName,
                        );
                    }
                    const collectionExportPath = getCollectionExportPath(
                        exportDir,
                        collectionExportName,
                    );
                    await ensureElectron().checkExistsAndCreateDir(
                        collectionExportPath,
                    );
                    await ensureElectron().checkExistsAndCreateDir(
                        getMetadataFolderExportPath(collectionExportPath),
                    );
                    await this.downloadAndSave(
                        exportDir,
                        collectionExportPath,
                        file,
                    );
                    incrementSuccess();
                    log.info(
                        `exporting file ${file.metadata.title} with id ${
                            file.id
                        } from collection ${collectionIDNameMap.get(
                            file.collectionID,
                        )} successful`,
                    );
                } catch (e) {
                    incrementFailed();
                    log.error("export failed for a file", e);
                    if (
                        e.message ===
                            CustomError.UPDATE_EXPORTED_RECORD_FAILED ||
                        e.message ===
                            CustomError.EXPORT_FOLDER_DOES_NOT_EXIST ||
                        e.message === CustomError.EXPORT_STOPPED
                    ) {
                        throw e;
                    }
                }
            }
        } catch (e) {
            if (
                e.message !== CustomError.EXPORT_FOLDER_DOES_NOT_EXIST &&
                e.message !== CustomError.EXPORT_STOPPED
            ) {
                log.error("fileExporter failed", e);
            }
            throw e;
        }
    }

    async fileTrasher(
        exportDir: string,
        collectionIDExportNameMap: Map<number, string>,
        removedFileUIDs: string[],
        isCanceled: CancellationStatus,
    ): Promise<void> {
        try {
            const exportRecord = await this.getExportRecord(exportDir);
            const fileIDExportNameMap = convertFileIDExportNameObjectToMap(
                exportRecord.fileExportNames,
            );
            for (const fileUID of removedFileUIDs) {
                await this.verifyExportFolderExists(exportDir);
                log.info(`trashing file with id ${fileUID}`);
                if (isCanceled.status) {
                    throw Error(CustomError.EXPORT_STOPPED);
                }
                try {
                    const fileExportName = fileIDExportNameMap.get(fileUID);
                    const collectionID = getCollectionIDFromFileUID(fileUID);
                    const collectionExportPath = getCollectionExportPath(
                        exportDir,
                        collectionIDExportNameMap.get(collectionID),
                    );
                    await this.removeFileExportedRecord(exportDir, fileUID);
                    try {
                        if (isLivePhotoExportName(fileExportName)) {
                            const {
                                image: imageExportName,
                                video: videoExportName,
                            } = parseLivePhotoExportName(fileExportName);
                            const imageExportPath = getFileExportPath(
                                collectionExportPath,
                                imageExportName,
                            );
                            log.info(
                                `moving image file ${imageExportPath} to trash folder`,
                            );
                            if (await this.exists(imageExportPath)) {
                                await ensureElectron().moveFile(
                                    imageExportPath,
                                    await getTrashedFileExportPath(
                                        exportDir,
                                        imageExportPath,
                                    ),
                                );
                            }

                            const imageMetadataFileExportPath =
                                getMetadataFileExportPath(imageExportPath);

                            if (
                                await this.exists(imageMetadataFileExportPath)
                            ) {
                                await ensureElectron().moveFile(
                                    imageMetadataFileExportPath,
                                    await getTrashedFileExportPath(
                                        exportDir,
                                        imageMetadataFileExportPath,
                                    ),
                                );
                            }

                            const videoExportPath = getFileExportPath(
                                collectionExportPath,
                                videoExportName,
                            );
                            log.info(
                                `moving video file ${videoExportPath} to trash folder`,
                            );
                            if (await this.exists(videoExportPath)) {
                                await ensureElectron().moveFile(
                                    videoExportPath,
                                    await getTrashedFileExportPath(
                                        exportDir,
                                        videoExportPath,
                                    ),
                                );
                            }
                            const videoMetadataFileExportPath =
                                getMetadataFileExportPath(videoExportPath);
                            if (
                                await this.exists(videoMetadataFileExportPath)
                            ) {
                                await ensureElectron().moveFile(
                                    videoMetadataFileExportPath,
                                    await getTrashedFileExportPath(
                                        exportDir,
                                        videoMetadataFileExportPath,
                                    ),
                                );
                            }
                        } else {
                            const fileExportPath = getFileExportPath(
                                collectionExportPath,
                                fileExportName,
                            );
                            const trashedFilePath =
                                await getTrashedFileExportPath(
                                    exportDir,
                                    fileExportPath,
                                );
                            log.info(
                                `moving file ${fileExportPath} to ${trashedFilePath} trash folder`,
                            );
                            if (await this.exists(fileExportPath)) {
                                await ensureElectron().moveFile(
                                    fileExportPath,
                                    trashedFilePath,
                                );
                            }
                            const metadataFileExportPath =
                                getMetadataFileExportPath(fileExportPath);
                            if (await this.exists(metadataFileExportPath)) {
                                await ensureElectron().moveFile(
                                    metadataFileExportPath,
                                    await getTrashedFileExportPath(
                                        exportDir,
                                        metadataFileExportPath,
                                    ),
                                );
                            }
                        }
                    } catch (e) {
                        await this.addFileExportedRecord(
                            exportDir,
                            fileUID,
                            fileExportName,
                        );
                        throw e;
                    }
                    log.info(`trashing file with id ${fileUID} successful`);
                } catch (e) {
                    log.error("trashing failed for a file", e);
                    if (
                        e.message ===
                            CustomError.UPDATE_EXPORTED_RECORD_FAILED ||
                        e.message ===
                            CustomError.EXPORT_FOLDER_DOES_NOT_EXIST ||
                        e.message === CustomError.EXPORT_STOPPED
                    ) {
                        throw e;
                    }
                }
            }
        } catch (e) {
            if (
                e.message !== CustomError.EXPORT_FOLDER_DOES_NOT_EXIST &&
                e.message !== CustomError.EXPORT_STOPPED
            ) {
                log.error("fileTrasher failed", e);
            }
            throw e;
        }
    }

    async addFileExportedRecord(
        folder: string,
        fileUID: string,
        fileExportName: string,
    ) {
        try {
            const exportRecord = await this.getExportRecord(folder);
            if (!exportRecord.fileExportNames) {
                exportRecord.fileExportNames = {};
            }
            exportRecord.fileExportNames = {
                ...exportRecord.fileExportNames,
                [fileUID]: fileExportName,
            };
            await this.updateExportRecord(folder, exportRecord);
        } catch (e) {
            if (e.message !== CustomError.EXPORT_FOLDER_DOES_NOT_EXIST) {
                log.error("addFileExportedRecord failed", e);
            }
            throw e;
        }
    }

    async addCollectionExportedRecord(
        folder: string,
        collectionID: number,
        collectionExportName: string,
    ) {
        try {
            const exportRecord = await this.getExportRecord(folder);
            if (!exportRecord?.collectionExportNames) {
                exportRecord.collectionExportNames = {};
            }
            exportRecord.collectionExportNames = {
                ...exportRecord.collectionExportNames,
                [collectionID]: collectionExportName,
            };

            await this.updateExportRecord(folder, exportRecord);
        } catch (e) {
            if (e.message !== CustomError.EXPORT_FOLDER_DOES_NOT_EXIST) {
                log.error("addCollectionExportedRecord failed", e);
            }
            throw e;
        }
    }

    async removeCollectionExportedRecord(folder: string, collectionID: number) {
        try {
            const exportRecord = await this.getExportRecord(folder);

            exportRecord.collectionExportNames = Object.fromEntries(
                Object.entries(exportRecord.collectionExportNames).filter(
                    ([key]) => key !== collectionID.toString(),
                ),
            );

            await this.updateExportRecord(folder, exportRecord);
        } catch (e) {
            if (e.message !== CustomError.EXPORT_FOLDER_DOES_NOT_EXIST) {
                log.error("removeCollectionExportedRecord failed", e);
            }
            throw e;
        }
    }

    async removeFileExportedRecord(folder: string, fileUID: string) {
        try {
            const exportRecord = await this.getExportRecord(folder);
            exportRecord.fileExportNames = Object.fromEntries(
                Object.entries(exportRecord.fileExportNames).filter(
                    ([key]) => key !== fileUID,
                ),
            );
            await this.updateExportRecord(folder, exportRecord);
        } catch (e) {
            if (e.message !== CustomError.EXPORT_FOLDER_DOES_NOT_EXIST) {
                log.error("removeFileExportedRecord failed", e);
            }
            throw e;
        }
    }

    async updateExportRecord(folder: string, newData: Partial<ExportRecord>) {
        const response = this.exportRecordUpdater.queueUpRequest(() =>
            this.updateExportRecordHelper(folder, newData),
        );
        return response.promise;
    }

    async updateExportRecordHelper(
        folder: string,
        newData: Partial<ExportRecord>,
    ) {
        try {
            const exportRecord = await this.getExportRecord(folder);
            const newRecord: ExportRecord = { ...exportRecord, ...newData };
            await ensureElectron().saveFileToDisk(
                `${folder}/${EXPORT_RECORD_FILE_NAME}`,
                JSON.stringify(newRecord, null, 2),
            );
            return newRecord;
        } catch (e) {
            if (e.message === CustomError.EXPORT_FOLDER_DOES_NOT_EXIST) {
                throw e;
            }
            log.error("error updating Export Record", e);
            throw Error(CustomError.UPDATE_EXPORTED_RECORD_FAILED);
        }
    }

    async getExportRecord(folder: string, retry = true): Promise<ExportRecord> {
        try {
            await this.verifyExportFolderExists(folder);
            const exportRecordJSONPath = `${folder}/${EXPORT_RECORD_FILE_NAME}`;
            if (!(await this.exists(exportRecordJSONPath))) {
                return this.createEmptyExportRecord(exportRecordJSONPath);
            }
            const recordFile =
                await ensureElectron().readTextFile(exportRecordJSONPath);
            try {
                return JSON.parse(recordFile);
            } catch (e) {
                throw Error(CustomError.EXPORT_RECORD_JSON_PARSING_FAILED);
            }
        } catch (e) {
            if (
                e.message === CustomError.EXPORT_RECORD_JSON_PARSING_FAILED &&
                retry
            ) {
                await sleep(1000);
                return await this.getExportRecord(folder, false);
            }
            if (e.message !== CustomError.EXPORT_FOLDER_DOES_NOT_EXIST) {
                log.error("export Record JSON parsing failed", e);
            }
            throw e;
        }
    }

    async createNewCollectionExport(
        exportFolder: string,
        collectionID: number,
        collectionIDNameMap: Map<number, string>,
    ) {
        await this.verifyExportFolderExists(exportFolder);
        const collectionName = collectionIDNameMap.get(collectionID);
        const collectionExportName = await getUniqueCollectionExportName(
            exportFolder,
            collectionName,
        );
        const collectionExportPath = getCollectionExportPath(
            exportFolder,
            collectionExportName,
        );
        await ensureElectron().checkExistsAndCreateDir(collectionExportPath);
        await ensureElectron().checkExistsAndCreateDir(
            getMetadataFolderExportPath(collectionExportPath),
        );

        return collectionExportName;
    }

    async downloadAndSave(
        exportDir: string,
        collectionExportPath: string,
        file: EnteFile,
    ): Promise<void> {
        try {
            const fileUID = getExportRecordFileUID(file);
            const originalFileStream = await downloadManager.getFile(file);
            if (!this.fileReader) {
                this.fileReader = new FileReader();
            }
            const updatedFileStream = await getUpdatedEXIFFileForDownload(
                this.fileReader,
                file,
                originalFileStream,
            );
            if (file.metadata.fileType === FILE_TYPE.LIVE_PHOTO) {
                await this.exportLivePhoto(
                    exportDir,
                    fileUID,
                    collectionExportPath,
                    updatedFileStream,
                    file,
                );
            } else {
                const fileExportName = await getUniqueFileExportName(
                    collectionExportPath,
                    file.metadata.title,
                );
                await this.addFileExportedRecord(
                    exportDir,
                    fileUID,
                    fileExportName,
                );
                try {
                    await this.saveMetadataFile(
                        collectionExportPath,
                        fileExportName,
                        file,
                    );
                    await ensureElectron().saveStreamToDisk(
                        getFileExportPath(collectionExportPath, fileExportName),
                        updatedFileStream,
                    );
                } catch (e) {
                    await this.removeFileExportedRecord(exportDir, fileUID);
                    throw e;
                }
            }
        } catch (e) {
            log.error("download and save failed", e);
            throw e;
        }
    }

    private async exportLivePhoto(
        exportDir: string,
        fileUID: string,
        collectionExportPath: string,
        fileStream: ReadableStream<any>,
        file: EnteFile,
    ) {
        const fileBlob = await new Response(fileStream).blob();
        const livePhoto = await decodeLivePhoto(file, fileBlob);
        const imageExportName = await getUniqueFileExportName(
            collectionExportPath,
            livePhoto.imageNameTitle,
        );
        const videoExportName = await getUniqueFileExportName(
            collectionExportPath,
            livePhoto.videoNameTitle,
        );
        const livePhotoExportName = getLivePhotoExportName(
            imageExportName,
            videoExportName,
        );
        await this.addFileExportedRecord(
            exportDir,
            fileUID,
            livePhotoExportName,
        );
        try {
            const imageStream = generateStreamFromArrayBuffer(livePhoto.image);
            await this.saveMetadataFile(
                collectionExportPath,
                imageExportName,
                file,
            );
            await ensureElectron().saveStreamToDisk(
                getFileExportPath(collectionExportPath, imageExportName),
                imageStream,
            );

            const videoStream = generateStreamFromArrayBuffer(livePhoto.video);
            await this.saveMetadataFile(
                collectionExportPath,
                videoExportName,
                file,
            );
            try {
                await ensureElectron().saveStreamToDisk(
                    getFileExportPath(collectionExportPath, videoExportName),
                    videoStream,
                );
            } catch (e) {
                await ensureElectron().deleteFile(
                    getFileExportPath(collectionExportPath, imageExportName),
                );
                throw e;
            }
        } catch (e) {
            await this.removeFileExportedRecord(exportDir, fileUID);
            throw e;
        }
    }

    private async saveMetadataFile(
        collectionExportPath: string,
        fileExportName: string,
        file: EnteFile,
    ) {
        await ensureElectron().saveFileToDisk(
            getFileMetadataExportPath(collectionExportPath, fileExportName),
            getGoogleLikeMetadataFile(fileExportName, file),
        );
    }

    isExportInProgress = () => {
        return this.exportInProgress;
    };

    exists = (path: string) => {
        return ensureElectron().fs.exists(path);
    };

    rename = (oldPath: string, newPath: string) => {
        return ensureElectron().rename(oldPath, newPath);
    };

    checkExistsAndCreateDir = (path: string) => {
        return ensureElectron().checkExistsAndCreateDir(path);
    };

    exportFolderExists = async (exportFolder: string) => {
        return exportFolder && (await this.exists(exportFolder));
    };

    private verifyExportFolderExists = async (exportFolder: string) => {
        try {
            if (!(await this.exportFolderExists(exportFolder))) {
                throw Error(CustomError.EXPORT_FOLDER_DOES_NOT_EXIST);
            }
        } catch (e) {
            if (e.message !== CustomError.EXPORT_FOLDER_DOES_NOT_EXIST) {
                log.error("verifyExportFolderExists failed", e);
            }
            throw e;
        }
    };

    private createEmptyExportRecord = async (exportRecordJSONPath: string) => {
        const exportRecord: ExportRecord = NULL_EXPORT_RECORD;
        await ensureElectron().saveFileToDisk(
            exportRecordJSONPath,
            JSON.stringify(exportRecord, null, 2),
        );
        return exportRecord;
    };
}
export default new ExportService();
