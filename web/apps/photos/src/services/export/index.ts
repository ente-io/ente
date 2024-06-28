import { FILE_TYPE } from "@/media/file-type";
import { decodeLivePhoto } from "@/media/live-photo";
import type { Metadata } from "@/media/types/file";
import { getAllLocalFiles } from "@/new/photos/services/files";
import { EnteFile } from "@/new/photos/types/file";
import { ensureElectron } from "@/next/electron";
import log from "@/next/log";
import { wait } from "@/utils/promise";
import { CustomError } from "@ente/shared/error";
import { Events, eventBus } from "@ente/shared/events";
import { LS_KEYS, getData, setData } from "@ente/shared/storage/localStorage";
import { formatDateTimeShort } from "@ente/shared/time/format";
import type { User } from "@ente/shared/user/types";
import QueueProcessor, {
    CancellationStatus,
    RequestCanceller,
} from "@ente/shared/utils/queueProcessor";
import { Collection } from "types/collection";
import {
    CollectionExportNames,
    ExportProgress,
    ExportRecord,
    ExportSettings,
    ExportUIUpdaters,
    FileExportNames,
} from "types/export";
import {
    constructCollectionNameMap,
    getCollectionUserFacingName,
    getNonEmptyPersonalCollections,
} from "utils/collection";
import {
    getPersonalFiles,
    getUpdatedEXIFFileForDownload,
    mergeMetadata,
} from "utils/file";
import { safeDirectoryName, safeFileName } from "utils/native-fs";
import { writeStream } from "utils/native-stream";
import { getAllLocalCollections } from "../collectionService";
import downloadManager from "../download";
import { migrateExport } from "./migration";

/** Name of the JSON file in which we keep the state of the export. */
const exportRecordFileName = "export_status.json";

/**
 * Name of the top level directory which we create underneath the selected
 * directory when the user starts an export to the file system.
 */
const exportDirectoryName = "Ente Photos";

/**
 * Name of the directory in which we put our metadata when exporting to the file
 * system.
 */
export const exportMetadataDirectoryName = "metadata";

/**
 * Name of the directory in which we keep trash items when deleting files that
 * have been exported to the local disk previously.
 */
export const exportTrashDirectoryName = "Trash";

export enum ExportStage {
    INIT = 0,
    MIGRATION = 1,
    STARTING = 2,
    EXPORTING_FILES = 3,
    TRASHING_DELETED_FILES = 4,
    RENAMING_COLLECTION_FOLDERS = 5,
    TRASHING_DELETED_COLLECTIONS = 6,
    FINISHED = 7,
}

export const NULL_EXPORT_RECORD: ExportRecord = {
    version: 3,
    lastAttemptTimestamp: null,
    stage: ExportStage.INIT,
    fileExportNames: {},
    collectionExportNames: {},
};

export interface ExportOpts {
    /**
     * If true, perform an additional on-disk check to determine which files
     * need to be exported.
     *
     * This has performance implications for huge libraries, so we only do this:
     * - For the first export after an app start
     * - If the user explicitly presses the "Resync" button.
     */
    resync?: boolean;
}

class ExportService {
    private exportSettings: ExportSettings;
    private exportInProgress: RequestCanceller = null;
    private resync = true;
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

    private resyncOnce() {
        const resync = this.resync;
        this.resync = false;
        return resync;
    }

    resumeExport() {
        this.scheduleExport({ resync: this.resyncOnce() });
    }

    enableContinuousExport() {
        try {
            if (this.continuousExportEventHandler) {
                log.info("continuous export already enabled");
                return;
            }
            log.info("enabling continuous export");
            this.continuousExportEventHandler = () => {
                this.scheduleExport({ resync: this.resyncOnce() });
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
                undefined,
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

    scheduleExport = async (exportOpts: ExportOpts) => {
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
                await this.runExport(exportFolder, isCanceled, exportOpts);
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
                        setTimeout(() => this.scheduleExport(exportOpts), 0);
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
        { resync }: ExportOpts,
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

            const diskFileRecordIDs = resync
                ? await readOnDiskFileExportRecordIDs(
                      personalFiles,
                      collectionIDExportNameMap,
                      exportFolder,
                      exportRecord,
                      isCanceled,
                  )
                : undefined;

            const filesToExport = getUnExportedFiles(
                personalFiles,
                exportRecord,
                diskFileRecordIDs,
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
        const fs = ensureElectron().fs;
        try {
            for (const collection of renamedCollections) {
                try {
                    if (isCanceled.status) {
                        throw Error(CustomError.EXPORT_STOPPED);
                    }
                    await this.verifyExportFolderExists(exportFolder);
                    const oldCollectionExportName =
                        collectionIDExportNameMap.get(collection.id);
                    const oldCollectionExportPath = `${exportFolder}/${oldCollectionExportName}`;
                    const newCollectionExportName = await safeDirectoryName(
                        exportFolder,
                        getCollectionUserFacingName(collection),
                        fs.exists,
                    );
                    log.info(
                        `renaming collection with id ${collection.id} from ${oldCollectionExportName} to ${newCollectionExportName}`,
                    );
                    const newCollectionExportPath = `${exportFolder}/${newCollectionExportName}`;
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
                        await fs.rename(
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
        const fs = ensureElectron().fs;
        const rmdirIfExists = async (dirPath: string) => {
            if (await fs.exists(dirPath)) await fs.rmdir(dirPath);
        };
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
                    const collectionExportPath = `${exportFolder}/${collectionExportName}`;
                    await this.removeCollectionExportedRecord(
                        exportFolder,
                        collectionID,
                    );
                    try {
                        // delete the collection metadata folder
                        await rmdirIfExists(
                            getMetadataFolderExportPath(collectionExportPath),
                        );
                        // delete the collection folder
                        await rmdirIfExists(collectionExportPath);
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
        const fs = ensureElectron().fs;
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
                    const collectionExportPath = `${exportDir}/${collectionExportName}`;
                    await fs.mkdirIfNeeded(collectionExportPath);
                    await fs.mkdirIfNeeded(
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
                    const collectionExportName =
                        collectionIDExportNameMap.get(collectionID);

                    if (isLivePhotoExportName(fileExportName)) {
                        const { image, video } =
                            parseLivePhotoExportName(fileExportName);

                        await moveToTrash(
                            exportDir,
                            collectionExportName,
                            image,
                        );

                        await moveToTrash(
                            exportDir,
                            collectionExportName,
                            video,
                        );
                    } else {
                        await moveToTrash(
                            exportDir,
                            collectionExportName,
                            fileExportName,
                        );
                    }

                    await this.removeFileExportedRecord(exportDir, fileUID);

                    log.info(`Moved file id ${fileUID} to Trash`);
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
            await ensureElectron().fs.writeFile(
                `${folder}/${exportRecordFileName}`,
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
        const electron = ensureElectron();
        const fs = electron.fs;
        try {
            await this.verifyExportFolderExists(folder);
            const exportRecordJSONPath = `${folder}/${exportRecordFileName}`;
            if (!(await fs.exists(exportRecordJSONPath))) {
                return this.createEmptyExportRecord(exportRecordJSONPath);
            }
            const recordFile = await fs.readTextFile(exportRecordJSONPath);
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
                await wait(1000);
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
        const fs = ensureElectron().fs;
        await this.verifyExportFolderExists(exportFolder);
        const collectionName = collectionIDNameMap.get(collectionID);
        const collectionExportName = await safeDirectoryName(
            exportFolder,
            collectionName,
            fs.exists,
        );
        const collectionExportPath = `${exportFolder}/${collectionExportName}`;
        await fs.mkdirIfNeeded(collectionExportPath);
        await fs.mkdirIfNeeded(
            getMetadataFolderExportPath(collectionExportPath),
        );

        return collectionExportName;
    }

    async downloadAndSave(
        exportDir: string,
        collectionExportPath: string,
        file: EnteFile,
    ): Promise<void> {
        const electron = ensureElectron();
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
                const fileExportName = await safeFileName(
                    collectionExportPath,
                    file.metadata.title,
                    electron.fs.exists,
                );
                await this.saveMetadataFile(
                    collectionExportPath,
                    fileExportName,
                    file,
                );
                await writeStream(
                    electron,
                    `${collectionExportPath}/${fileExportName}`,
                    updatedFileStream,
                );
                await this.addFileExportedRecord(
                    exportDir,
                    fileUID,
                    fileExportName,
                );
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
        const fs = ensureElectron().fs;
        const fileBlob = await new Response(fileStream).blob();
        const livePhoto = await decodeLivePhoto(file.metadata.title, fileBlob);
        const imageExportName = await safeFileName(
            collectionExportPath,
            livePhoto.imageFileName,
            fs.exists,
        );
        const videoExportName = await safeFileName(
            collectionExportPath,
            livePhoto.videoFileName,
            fs.exists,
        );

        const livePhotoExportName = getLivePhotoExportName(
            imageExportName,
            videoExportName,
        );

        await this.saveMetadataFile(
            collectionExportPath,
            imageExportName,
            file,
        );
        await writeStream(
            electron,
            `${collectionExportPath}/${imageExportName}`,
            new Response(livePhoto.imageData).body,
        );

        await this.saveMetadataFile(
            collectionExportPath,
            videoExportName,
            file,
        );
        try {
            await writeStream(
                electron,
                `${collectionExportPath}/${videoExportName}`,
                new Response(livePhoto.videoData).body,
            );
        } catch (e) {
            await fs.rm(`${collectionExportPath}/${imageExportName}`);
            throw e;
        }

        await this.addFileExportedRecord(
            exportDir,
            fileUID,
            livePhotoExportName,
        );
    }

    private async saveMetadataFile(
        collectionExportPath: string,
        fileExportName: string,
        file: EnteFile,
    ) {
        await ensureElectron().fs.writeFile(
            getFileMetadataExportPath(collectionExportPath, fileExportName),
            getGoogleLikeMetadataFile(fileExportName, file),
        );
    }

    isExportInProgress = () => {
        return this.exportInProgress;
    };

    exportFolderExists = async (exportFolder: string) => {
        return exportFolder && (await ensureElectron().fs.exists(exportFolder));
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
        await ensureElectron().fs.writeFile(
            exportRecordJSONPath,
            JSON.stringify(exportRecord, null, 2),
        );
        return exportRecord;
    };
}

const exportService = new ExportService();

export default exportService;

/**
 * If there are any in-progress exports, or if continuous exports are enabled,
 * resume them.
 */
export const resumeExportsIfNeeded = async () => {
    const exportSettings = exportService.getExportSettings();
    if (!(await exportService.exportFolderExists(exportSettings?.folder))) {
        return;
    }
    const exportRecord = await exportService.getExportRecord(
        exportSettings.folder,
    );
    if (exportSettings.continuousExport) {
        exportService.enableContinuousExport();
    }
    if (isExportInProgress(exportRecord.stage)) {
        log.debug(() => "Resuming in-progress export");
        exportService.resumeExport();
    }
};

/**
 * Prompt the user to select a directory and create an export directory in it.
 *
 * If the user cancels the selection, return undefined.
 */
export const selectAndPrepareExportDirectory = async (): Promise<
    string | undefined
> => {
    const electron = ensureElectron();

    const rootDir = await electron.selectDirectory();
    if (!rootDir) return undefined;

    const exportDir = `${rootDir}/${exportDirectoryName}`;
    await electron.fs.mkdirIfNeeded(exportDir);
    return exportDir;
};

export const getExportRecordFileUID = (file: EnteFile) =>
    `${file.id}_${file.collectionID}_${file.updationTime}`;

export const getCollectionIDFromFileUID = (fileUID: string) =>
    Number(fileUID.split("_")[1]);

const convertCollectionIDExportNameObjectToMap = (
    collectionExportNames: CollectionExportNames,
): Map<number, string> => {
    return new Map<number, string>(
        Object.entries(collectionExportNames ?? {}).map((e) => {
            return [Number(e[0]), String(e[1])];
        }),
    );
};

const convertFileIDExportNameObjectToMap = (
    fileExportNames: FileExportNames,
): Map<string, string> => {
    return new Map<string, string>(
        Object.entries(fileExportNames ?? {}).map((e) => {
            return [String(e[0]), String(e[1])];
        }),
    );
};

const getRenamedExportedCollections = (
    collections: Collection[],
    exportRecord: ExportRecord,
) => {
    if (!exportRecord?.collectionExportNames) {
        return [];
    }
    const collectionIDExportNameMap = convertCollectionIDExportNameObjectToMap(
        exportRecord.collectionExportNames,
    );
    const renamedCollections = collections.filter((collection) => {
        if (collectionIDExportNameMap.has(collection.id)) {
            const currentExportName = collectionIDExportNameMap.get(
                collection.id,
            );

            const collectionExportName =
                getCollectionUserFacingName(collection);

            if (currentExportName === collectionExportName) {
                return false;
            }
            const hasNumberedSuffix = currentExportName.match(/\(\d+\)$/);
            const currentExportNameWithoutNumberedSuffix = hasNumberedSuffix
                ? currentExportName.replace(/\(\d+\)$/, "")
                : currentExportName;

            return (
                collectionExportName !== currentExportNameWithoutNumberedSuffix
            );
        }
        return false;
    });
    return renamedCollections;
};

const getDeletedExportedCollections = (
    collections: Collection[],
    exportRecord: ExportRecord,
) => {
    if (!exportRecord?.collectionExportNames) {
        return [];
    }
    const presentCollections = new Set(
        collections.map((collection) => collection.id),
    );
    const deletedExportedCollections = Object.keys(
        exportRecord?.collectionExportNames,
    )
        .map(Number)
        .filter((collectionID) => {
            if (!presentCollections.has(collectionID)) {
                return true;
            }
            return false;
        });
    return deletedExportedCollections;
};

/**
 * Return export record IDs of {@link files} for which there is also exists a
 * file on disk.
 */
const readOnDiskFileExportRecordIDs = async (
    files: EnteFile[],
    collectionIDFolderNameMap: Map<number, string>,
    exportDir: string,
    exportRecord: ExportRecord,
    isCanceled: CancellationStatus,
): Promise<Set<string>> => {
    const fs = ensureElectron().fs;

    const result = new Set<string>();
    if (!(await fs.exists(exportDir))) return result;

    const fileExportNames = exportRecord.fileExportNames ?? {};

    for (const file of files) {
        if (isCanceled.status) throw Error(CustomError.EXPORT_STOPPED);

        const collectionExportName = collectionIDFolderNameMap.get(
            file.collectionID,
        );
        if (!collectionExportName) continue;

        const collectionExportPath = `${exportDir}/${collectionExportName}`;
        const recordID = getExportRecordFileUID(file);
        const exportName = fileExportNames[recordID];
        if (!exportName) continue;

        let fileName: string;
        let fileName2: string | undefined; // Live photos have 2 parts
        if (isLivePhotoExportName(exportName)) {
            const { image, video } = parseLivePhotoExportName(exportName);
            fileName = image;
            fileName2 = video;
        } else {
            fileName = exportName;
        }

        const filePath = `${collectionExportPath}/${fileName}`;
        if (await fs.exists(filePath)) {
            // Also check that the sibling part exists (if any).
            if (fileName2) {
                const filePath2 = `${collectionExportPath}/${fileName2}`;
                if (await fs.exists(filePath2)) result.add(recordID);
            } else {
                result.add(recordID);
            }
        }
    }

    return result;
};

/**
 * Return the list of files from amongst {@link allFiles} that still need to be
 * exported.
 *
 * @param allFiles The list of files to export.
 *
 * @param exportRecord The export record containing bookeeping for the export.
 *
 * @paramd diskFileRecordIDs (Optional) The export record IDs of files from
 * amongst {@link allFiles} that already exist on disk. If provided (e.g. when
 * doing a resync), we perform an extra check for on-disk existence instead of
 * relying solely on the export record.
 */
const getUnExportedFiles = (
    allFiles: EnteFile[],
    exportRecord: ExportRecord,
    diskFileRecordIDs: Set<string> | undefined,
) => {
    if (!exportRecord?.fileExportNames) {
        return allFiles;
    }
    const exportedFiles = new Set(Object.keys(exportRecord?.fileExportNames));
    return allFiles.filter((file) => {
        const recordID = getExportRecordFileUID(file);
        if (!exportedFiles.has(recordID)) return true;
        if (diskFileRecordIDs && !diskFileRecordIDs.has(recordID)) return true;
        return false;
    });
};

const getDeletedExportedFiles = (
    allFiles: EnteFile[],
    exportRecord: ExportRecord,
): string[] => {
    if (!exportRecord?.fileExportNames) {
        return [];
    }
    const presentFileUIDs = new Set(
        allFiles?.map((file) => getExportRecordFileUID(file)),
    );
    const deletedExportedFiles = Object.keys(
        exportRecord?.fileExportNames,
    ).filter((fileUID) => {
        if (!presentFileUIDs.has(fileUID)) {
            return true;
        }
        return false;
    });
    return deletedExportedFiles;
};

const getCollectionExportedFiles = (
    exportRecord: ExportRecord,
    collectionID: number,
): string[] => {
    if (!exportRecord?.fileExportNames) {
        return [];
    }
    const collectionExportedFiles = Object.keys(
        exportRecord?.fileExportNames,
    ).filter((fileUID) => {
        const fileCollectionID = Number(fileUID.split("_")[1]);
        if (fileCollectionID === collectionID) {
            return true;
        } else {
            return false;
        }
    });
    return collectionExportedFiles;
};

const getGoogleLikeMetadataFile = (fileExportName: string, file: EnteFile) => {
    const metadata: Metadata = file.metadata;
    const creationTime = Math.floor(metadata.creationTime / 1000000);
    const modificationTime = Math.floor(
        (metadata.modificationTime ?? metadata.creationTime) / 1000000,
    );
    const captionValue: string = file?.pubMagicMetadata?.data?.caption;
    return JSON.stringify(
        {
            title: fileExportName,
            caption: captionValue,
            creationTime: {
                timestamp: creationTime,
                formatted: formatDateTimeShort(creationTime * 1000),
            },
            modificationTime: {
                timestamp: modificationTime,
                formatted: formatDateTimeShort(modificationTime * 1000),
            },
            geoData: {
                latitude: metadata.latitude,
                longitude: metadata.longitude,
            },
        },
        null,
        2,
    );
};

export const getMetadataFolderExportPath = (collectionExportPath: string) =>
    `${collectionExportPath}/${exportMetadataDirectoryName}`;

// if filepath is /home/user/Ente/Export/Collection1/1.jpg
// then metadata path is /home/user/Ente/Export/Collection1/ENTE_METADATA_FOLDER/1.jpg.json
const getFileMetadataExportPath = (
    collectionExportPath: string,
    fileExportName: string,
) =>
    `${collectionExportPath}/${exportMetadataDirectoryName}/${fileExportName}.json`;

export const getLivePhotoExportName = (
    imageExportName: string,
    videoExportName: string,
) =>
    JSON.stringify({
        image: imageExportName,
        video: videoExportName,
    });

export const isLivePhotoExportName = (exportName: string) => {
    try {
        JSON.parse(exportName);
        return true;
    } catch (e) {
        return false;
    }
};

const parseLivePhotoExportName = (
    livePhotoExportName: string,
): { image: string; video: string } => {
    const { image, video } = JSON.parse(livePhotoExportName);
    return { image, video };
};

const isExportInProgress = (exportStage: ExportStage) =>
    exportStage > ExportStage.INIT && exportStage < ExportStage.FINISHED;

/**
 * Move {@link fileName} in {@link collectionName} to Trash.
 *
 * Also move its associated metadata JSON to Trash.
 *
 * @param exportDir The root directory on the user's file system where we are
 * exporting to.
 * */
const moveToTrash = async (
    exportDir: string,
    collectionName: string,
    fileName: string,
) => {
    const fs = ensureElectron().fs;

    const filePath = `${exportDir}/${collectionName}/${fileName}`;
    const trashDir = `${exportDir}/${exportTrashDirectoryName}/${collectionName}`;
    const metadataFileName = `${fileName}.json`;
    const metadataFilePath = `${exportDir}/${collectionName}/${exportMetadataDirectoryName}/${metadataFileName}`;
    const metadataTrashDir = `${exportDir}/${exportTrashDirectoryName}/${collectionName}/${exportMetadataDirectoryName}`;

    log.info(`Moving file ${filePath} and its metadata to trash folder`);

    if (await fs.exists(filePath)) {
        await fs.mkdirIfNeeded(trashDir);
        const trashFileName = await safeFileName(trashDir, fileName, fs.exists);
        const trashFilePath = `${trashDir}/${trashFileName}`;
        await fs.rename(filePath, trashFilePath);
    }

    if (await fs.exists(metadataFilePath)) {
        await fs.mkdirIfNeeded(metadataTrashDir);
        const metadataTrashFileName = await safeFileName(
            metadataTrashDir,
            metadataFileName,
            fs.exists,
        );
        const metadataTrashFilePath = `${metadataTrashDir}/${metadataTrashFileName}`;
        await fs.rename(metadataFilePath, metadataTrashFilePath);
    }
};
