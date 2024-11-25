import { ensureElectron } from "@/base/electron";
import log from "@/base/log";
import { downloadManager } from "@/gallery/services/download";
import { writeStream } from "@/gallery/utils/native-stream";
import type { Collection } from "@/media/collection";
import { mergeMetadata, type EnteFile } from "@/media/file";
import {
    fileCreationPhotoDate,
    fileLocation,
    type Metadata,
} from "@/media/file-metadata";
import { FileType } from "@/media/file-type";
import { decodeLivePhoto } from "@/media/live-photo";
import {
    createCollectionNameByID,
    getCollectionUserFacingName,
} from "@/new/photos/services/collection";
import {
    exportMetadataDirectoryName,
    exportTrashDirectoryName,
} from "@/new/photos/services/export";
import { getAllLocalFiles } from "@/new/photos/services/files";
import { safeDirectoryName, safeFileName } from "@/new/photos/utils/native-fs";
import { PromiseQueue } from "@/utils/promise";
import { CustomError } from "@ente/shared/error";
import { LS_KEYS, getData, setData } from "@ente/shared/storage/localStorage";
import i18n from "i18next";
import {
    CollectionExportNames,
    ExportProgress,
    ExportRecord,
    ExportSettings,
    ExportUIUpdaters,
    FileExportNames,
} from "types/export";
import { getAllLocalCollections } from "../collectionService";
import { migrateExport } from "./migration";

/** Name of the JSON file in which we keep the state of the export. */
const exportRecordFileName = "export_status.json";

/**
 * Name of the top level directory which we create underneath the selected
 * directory when the user starts an export to the file system.
 */
const exportDirectoryName = "Ente Photos";

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

interface RequestCanceller {
    exec: () => void;
}

interface CancellationStatus {
    status: boolean;
}

class ExportService {
    private exportSettings: ExportSettings;
    private exportInProgress: RequestCanceller = null;
    private resync = true;
    private reRunNeeded = false;
    private exportRecordUpdater = new PromiseQueue<ExportRecord>();
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
    private cachedMetadataDateTimeFormatter: Intl.DateTimeFormat;

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
        if (this.continuousExportEventHandler) {
            log.warn("Continuous export already enabled");
            return;
        }
        this.continuousExportEventHandler = () => {
            this.scheduleExport({ resync: this.resyncOnce() });
        };
        this.continuousExportEventHandler();
    }

    disableContinuousExport() {
        if (!this.continuousExportEventHandler) {
            log.warn("Continuous export already disabled");
            return;
        }
        this.continuousExportEventHandler = null;
    }

    /**
     * Called when the local database of files changes.
     */
    onLocalFilesUpdated() {
        if (this.continuousExportEventHandler) {
            this.continuousExportEventHandler();
        }
    }

    getPendingExports = async (
        exportRecord: ExportRecord,
    ): Promise<EnteFile[]> => {
        try {
            const files = await getAllLocalFiles();

            const unExportedFiles = getUnExportedFiles(
                files,
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
            const files = mergeMetadata(await getAllLocalFiles());
            const collections = await getAllLocalCollections();

            const exportRecord = await this.getExportRecord(exportFolder);
            const collectionIDExportNameMap =
                convertCollectionIDExportNameObjectToMap(
                    exportRecord.collectionExportNames,
                );
            const collectionIDNameMap = createCollectionNameByID(collections);

            const renamedCollections = getRenamedExportedCollections(
                collections,
                exportRecord,
            );

            const removedFileUIDs = getDeletedExportedFiles(
                files,
                exportRecord,
            );

            const diskFileRecordIDs = resync
                ? await readOnDiskFileExportRecordIDs(
                      files,
                      collectionIDExportNameMap,
                      exportFolder,
                      exportRecord,
                      isCanceled,
                  )
                : undefined;

            const filesToExport = getUnExportedFiles(
                files,
                exportRecord,
                diskFileRecordIDs,
            );

            const deletedExportedCollections = getDeletedExportedCollections(
                collections,
                exportRecord,
            );

            log.info(
                `files:${files.length} unexported files: ${filesToExport.length}, deleted exported files: ${removedFileUIDs.length}, renamed collections: ${renamedCollections.length}, deleted collections: ${deletedExportedCollections.length}`,
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
        return this.exportRecordUpdater.add(() =>
            this.updateExportRecordHelper(folder, newData),
        );
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

    async getExportRecord(folder: string): Promise<ExportRecord> {
        const electron = ensureElectron();
        const fs = electron.fs;
        try {
            await this.verifyExportFolderExists(folder);
            const exportRecordJSONPath = `${folder}/${exportRecordFileName}`;
            if (!(await fs.exists(exportRecordJSONPath))) {
                return await this.createEmptyExportRecord(exportRecordJSONPath);
            }
            const recordFile = await fs.readTextFile(exportRecordJSONPath);
            return JSON.parse(recordFile);
        } catch (e) {
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
            const originalFileStream = await downloadManager.fileStream(file);
            if (file.metadata.fileType === FileType.livePhoto) {
                await this.exportLivePhoto(
                    exportDir,
                    fileUID,
                    collectionExportPath,
                    originalFileStream,
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
                    originalFileStream,
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
        fileStream: ReadableStream,
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
        const formatter = this.metadataDateTimeFormatter();
        await ensureElectron().fs.writeFile(
            getFileMetadataExportPath(collectionExportPath, fileExportName),
            getGoogleLikeMetadataFile(fileExportName, file, formatter),
        );
    }

    /**
     * Lazily created, cached instance of the date time formatter that should be
     * used for formatting the dates added to the metadata file.
     */
    private metadataDateTimeFormatter() {
        if (this.cachedMetadataDateTimeFormatter)
            return this.cachedMetadataDateTimeFormatter;

        // AFAIK, Google's format is not documented. It also seems to vary with
        // locale. This is a best attempt at constructing a formatter that
        // mirrors the format used by the timestamps in the takeout JSON.
        const formatter = new Intl.DateTimeFormat(i18n.language, {
            month: "short",
            day: "numeric",
            year: "numeric",
            hour: "numeric",
            minute: "numeric",
            second: "numeric",
            timeZoneName: "short",
            timeZone: "UTC",
        });
        this.cachedMetadataDateTimeFormatter = formatter;
        return formatter;
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
            const hasNumberedSuffix = /\(\d+\)$/.exec(currentExportName);
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

    // Both the paths involved are guaranteed to use POSIX separators and thus
    // can directly be compared.
    //
    // -   `exportDir` traces its origin to `electron.selectDirectory()`, which
    //     returns POSIX paths. Down below we use it as the base directory when
    //     construction paths for the items to export.
    //
    // -   `findFiles` is also guaranteed to return POSIX paths.
    //
    const ls = new Set(await ensureElectron().fs.findFiles(exportDir));

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

        if (ls.has(`${collectionExportPath}/${exportName}`)) {
            result.add(recordID);
        } else {
            // It might be a live photo - these store a JSON string instead of
            // the file's name as the exportName.
            try {
                const { image, video } = parseLivePhotoExportName(exportName);
                if (
                    ls.has(`${collectionExportPath}/${image}`) &&
                    ls.has(`${collectionExportPath}/${video}`)
                ) {
                    result.add(recordID);
                }
            } catch {
                /* Not an error, the file just might not exist on disk yet */
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
 * @param exportRecord The export record containing bookkeeping for the export.
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

const getGoogleLikeMetadataFile = (
    fileExportName: string,
    file: EnteFile,
    dateTimeFormatter: Intl.DateTimeFormat,
) => {
    const metadata: Metadata = file.metadata;
    const creationTime = Math.floor(metadata.creationTime / 1e6);
    const modificationTime = Math.floor(
        (metadata.modificationTime ?? metadata.creationTime) / 1e6,
    );
    const result: Record<string, unknown> = {
        title: fileExportName,
        creationTime: {
            timestamp: creationTime,
            formatted: dateTimeFormatter.format(
                fileCreationPhotoDate(file, file.pubMagicMetadata?.data),
            ),
        },
        modificationTime: {
            timestamp: modificationTime,
            formatted: dateTimeFormatter.format(modificationTime * 1000),
        },
    };
    const caption = file?.pubMagicMetadata?.data?.caption;
    if (caption) result.caption = caption;
    const geoData = fileLocation(file);
    if (geoData) result.geoData = geoData;
    return JSON.stringify(result, null, 2);
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
    } catch {
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
