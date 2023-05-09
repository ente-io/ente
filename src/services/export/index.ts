import { runningInBrowser } from 'utils/common';
import {
    getUnExportedFiles,
    getGoogleLikeMetadataFile,
    getExportRecordFileUID,
    getUniqueCollectionExportName,
    getUniqueFileExportName,
    getFileMetadataExportPath,
    getFileExportPath,
    getRenamedExportedCollections,
    getDeletedExportedFiles,
    convertCollectionIDExportNameObjectToMap,
    convertFileIDExportNameObjectToMap,
    getDeletedExportedCollections,
    getTrashedFileExportPath,
    getMetadataFileExportPath,
    getCollectionExportedFiles,
    getCollectionExportPath,
    getMetadataFolderExportPath,
    getLivePhotoExportName,
    isLivePhotoExportName,
    parseLivePhotoExportName,
    getCollectionIDFromFileUID,
} from 'utils/export';
import { retryAsyncFunction } from 'utils/network';
import { logError } from 'utils/sentry';
import { getData, LS_KEYS, setData } from 'utils/storage/localStorage';
import { getLocalCollections } from '../collectionService';
import downloadManager from '../downloadManager';
import { getLocalFiles } from '../fileService';
import { EnteFile } from 'types/file';

import { decodeLivePhoto } from '../livePhotoService';
import {
    generateStreamFromArrayBuffer,
    getFileExtension,
    getPersonalFiles,
    mergeMetadata,
} from 'utils/file';

import { updateFileCreationDateInEXIF } from '../upload/exifService';
import QueueProcessor from '../queueProcessor';
import { Collection } from 'types/collection';
import {
    ExportProgress,
    ExportRecord,
    ExportSettings,
    ExportUIUpdaters,
    FileExportStats,
} from 'types/export';
import { User } from 'types/user';
import { FILE_TYPE, TYPE_JPEG, TYPE_JPG } from 'constants/file';
import { ExportStage } from 'constants/export';
import { ElectronAPIs } from 'types/electron';
import { CustomError } from 'utils/error';
import { addLocalLog, addLogLine } from 'utils/logging';
import { eventBus, Events } from '../events';
import {
    getCollectionNameMap,
    getNonEmptyPersonalCollections,
} from 'utils/collection';
import { migrateExportJSON } from './migration';

const EXPORT_RECORD_FILE_NAME = 'export_status.json';

export const ENTE_EXPORT_DIRECTORY = 'ente Photos';

export const NULL_EXPORT_RECORD: ExportRecord = {
    version: 3,
    lastAttemptTimestamp: null,
    stage: ExportStage.INIT,
    fileExportNames: {},
    collectionExportNames: {},
};

class ExportService {
    private electronAPIs: ElectronAPIs;
    private exportSettings: ExportSettings;
    private exportInProgress: boolean = false;
    private reRunNeeded = false;
    private exportRecordUpdater = new QueueProcessor<ExportRecord>(1);
    private stopExport: boolean = false;
    private fileReader: FileReader = null;
    private continuousExportEventHandler: () => void;
    private uiUpdater: ExportUIUpdaters = {
        setExportProgress: () => {},
        setExportStage: () => {},
        setLastExportTime: () => {},
        setFileExportStats: () => {},
    };
    private currentExportProgress: ExportProgress = {
        total: 0,
        success: 0,
        failed: 0,
    };
    private migrationInProgress: Promise<void>;

    constructor() {
        if (runningInBrowser()) {
            this.electronAPIs = window['ElectronAPIs'];
        }
    }

    getExportSettings(): ExportSettings {
        try {
            if (this.exportSettings) {
                return this.exportSettings;
            }
            const exportSettings = getData(LS_KEYS.EXPORT);
            this.exportSettings = exportSettings;
            return exportSettings;
        } catch (e) {
            logError(e, 'getExportSettings failed');
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
            logError(e, 'updateExportSettings failed');
            throw e;
        }
    }

    async runMigration(exportDir: string, exportRecord: ExportRecord) {
        try {
            addLogLine('running migration');
            this.migrationInProgress = migrateExportJSON(
                exportDir,
                exportRecord
            );
            await this.migrationInProgress;
            addLogLine('migration completed');
            this.migrationInProgress = null;
        } catch (e) {
            logError(e, 'migration failed');
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
        await this.updateExportRecord({ stage }, exportFolder);
        this.uiUpdater.setExportStage(stage);
    }

    private async updateLastExportTime(exportTime: number) {
        const exportFolder = this.getExportSettings()?.folder;
        await this.updateExportRecord(
            { lastAttemptTimestamp: exportTime },
            exportFolder
        );
        this.uiUpdater.setLastExportTime(exportTime);
    }

    async changeExportDirectory() {
        try {
            const newRootDir = await this.electronAPIs.selectRootDirectory();
            if (!newRootDir) {
                throw Error(CustomError.SELECT_FOLDER_ABORTED);
            }
            const newExportDir = `${newRootDir}/${ENTE_EXPORT_DIRECTORY}`;
            await this.electronAPIs.checkExistsAndCreateDir(newExportDir);
            return newExportDir;
        } catch (e) {
            if (e.message !== CustomError.SELECT_FOLDER_ABORTED) {
                logError(e, 'changeExportDirectory failed');
            }
            throw e;
        }
    }

    async openExportDirectory(exportFolder: string) {
        try {
            await this.electronAPIs.openDirectory(exportFolder);
        } catch (e) {
            logError(e, 'openExportDirectory failed');
        }
    }

    enableContinuousExport() {
        try {
            if (this.continuousExportEventHandler) {
                addLogLine('continuous export already enabled');
                return;
            }
            addLogLine('enabling continuous export');
            this.continuousExportEventHandler = () => {
                this.scheduleExport();
            };
            this.continuousExportEventHandler();
            eventBus.addListener(
                Events.LOCAL_FILES_UPDATED,
                this.continuousExportEventHandler
            );
        } catch (e) {
            logError(e, 'failed to enableContinuousExport ');
            throw e;
        }
    }

    disableContinuousExport() {
        try {
            if (!this.continuousExportEventHandler) {
                addLogLine('continuous export already disabled');
                return;
            }
            addLogLine('disabling continuous export');
            eventBus.removeListener(
                Events.LOCAL_FILES_UPDATED,
                this.continuousExportEventHandler
            );
            this.continuousExportEventHandler = null;
        } catch (e) {
            logError(e, 'failed to disableContinuousExport');
            throw e;
        }
    }

    getFileExportStats = async (
        exportRecord: ExportRecord
    ): Promise<FileExportStats> => {
        try {
            const user: User = getData(LS_KEYS.USER);
            const files = await getLocalFiles();
            const userPersonalFiles = getPersonalFiles(files, user);

            const collections = await getLocalCollections();
            const userNonEmptyPersonalCollections =
                getNonEmptyPersonalCollections(
                    collections,
                    userPersonalFiles,
                    user
                );

            const unExportedFiles = getUnExportedFiles(
                userPersonalFiles,
                exportRecord
            );
            const deletedExportedFiles = getDeletedExportedFiles(
                userPersonalFiles,
                exportRecord
            );
            const renamedCollections = getRenamedExportedCollections(
                userNonEmptyPersonalCollections,
                exportRecord
            );
            const deletedCollections = getDeletedExportedCollections(
                userNonEmptyPersonalCollections,
                exportRecord
            );

            addLocalLog(
                () =>
                    `personal files:${userPersonalFiles.length} unexported files: ${unExportedFiles.length}, deleted exported files: ${deletedExportedFiles.length}, renamed collections: ${renamedCollections.length}, deleted collections: ${deletedCollections.length}`
            );

            return {
                totalCount: userPersonalFiles.length,
                pendingCount:
                    unExportedFiles.length +
                    deletedExportedFiles.length +
                    renamedCollections.length +
                    deletedCollections.length,
            };
        } catch (e) {
            logError(e, 'getUpdateFileLists failed');
            throw e;
        }
    };

    async preExport(exportFolder: string) {
        this.verifyExportFolderExists(exportFolder);
        this.stopExport = false;
        await this.updateExportStage(ExportStage.INPROGRESS);
        this.updateExportProgress({
            success: 0,
            failed: 0,
            total: 0,
        });
    }

    async postExport() {
        try {
            const exportFolder = this.getExportSettings()?.folder;
            if (!this.exportFolderExists(exportFolder)) {
                this.uiUpdater.setExportStage(ExportStage.INIT);
                return;
            }
            await this.updateExportStage(ExportStage.FINISHED);
            await this.updateLastExportTime(Date.now());

            const exportRecord = await this.getExportRecord(exportFolder);

            const fileExportStats = await this.getFileExportStats(exportRecord);
            this.uiUpdater.setFileExportStats(fileExportStats);
        } catch (e) {
            logError(e, 'postExport failed');
        }
    }

    async stopRunningExport() {
        try {
            this.stopExport = true;
            this.reRunNeeded = false;
            await this.postExport();
        } catch (e) {
            logError(e, 'stopRunningExport failed');
        }
    }

    scheduleExport = async () => {
        try {
            if (this.exportInProgress) {
                addLogLine('export in progress, scheduling re-run');
                this.reRunNeeded = true;
                return;
            } else {
                addLogLine('export not in progress, starting export');
            }
            this.exportInProgress = true;
            if (this.migrationInProgress) {
                addLogLine('migration in progress, waiting for it to complete');
                await this.migrationInProgress;
                this.migrationInProgress = null;
            }
            try {
                const exportFolder = this.getExportSettings()?.folder;
                await this.preExport(exportFolder);
                addLogLine('export started');
                await this.runExport(exportFolder);
                addLogLine('export completed');
            } finally {
                this.exportInProgress = false;
                if (this.reRunNeeded) {
                    this.reRunNeeded = false;
                    addLogLine('re-running export');
                    setTimeout(() => this.scheduleExport(), 0);
                }
                await this.postExport();
            }
        } catch (e) {
            if (e.message !== CustomError.EXPORT_FOLDER_DOES_NOT_EXIST) {
                logError(e, 'scheduleExport failed');
            }
        }
    };

    private async runExport(exportFolder: string) {
        try {
            const user: User = getData(LS_KEYS.USER);
            const files = mergeMetadata(await getLocalFiles());
            const personalFiles = getPersonalFiles(files, user);

            const collections = await getLocalCollections();
            const nonEmptyPersonalCollections = getNonEmptyPersonalCollections(
                collections,
                personalFiles,
                user
            );

            const exportRecord = await this.getExportRecord(exportFolder);
            const collectionIDExportNameMap =
                convertCollectionIDExportNameObjectToMap(
                    exportRecord.collectionExportNames
                );
            const collectionIDNameMap = getCollectionNameMap(
                nonEmptyPersonalCollections
            );

            const renamedCollections = getRenamedExportedCollections(
                nonEmptyPersonalCollections,
                exportRecord
            );

            const removedFileUIDs = getDeletedExportedFiles(
                personalFiles,
                exportRecord
            );
            const filesToExport = getUnExportedFiles(
                personalFiles,
                exportRecord
            );
            const deletedExportedCollections = getDeletedExportedCollections(
                nonEmptyPersonalCollections,
                exportRecord
            );

            addLocalLog(
                () =>
                    `personal files:${personalFiles.length} unexported files: ${filesToExport.length}, deleted exported files: ${removedFileUIDs.length}, renamed collections: ${renamedCollections.length}, deleted collections: ${deletedExportedCollections.length}`
            );
            let success = 0;
            let failed = 0;
            this.uiUpdater.setExportProgress({
                success: success,
                failed: failed,
                total:
                    removedFileUIDs.length +
                    filesToExport.length +
                    deletedExportedCollections.length +
                    renamedCollections.length,
            });
            const incrementSuccess = () => {
                this.updateExportProgress({
                    success: ++success,
                    failed: failed,
                    total:
                        removedFileUIDs.length +
                        filesToExport.length +
                        deletedExportedCollections.length +
                        renamedCollections.length,
                });
            };
            const incrementFailed = () => {
                this.updateExportProgress({
                    success: success,
                    failed: ++failed,
                    total:
                        removedFileUIDs.length +
                        filesToExport.length +
                        deletedExportedCollections.length +
                        renamedCollections.length,
                });
            };
            if (renamedCollections?.length > 0) {
                addLogLine(`renaming ${renamedCollections.length} collections`);
                await this.collectionRenamer(
                    exportFolder,
                    collectionIDExportNameMap,
                    renamedCollections,
                    incrementSuccess,
                    incrementFailed
                );
            }

            if (removedFileUIDs?.length > 0) {
                addLogLine(`trashing ${removedFileUIDs.length} files`);
                await this.fileTrasher(
                    exportFolder,
                    collectionIDExportNameMap,
                    removedFileUIDs,
                    incrementSuccess,
                    incrementFailed
                );
            }
            if (filesToExport?.length > 0) {
                addLogLine(`exporting ${filesToExport.length} files`);
                await this.fileExporter(
                    filesToExport,
                    collectionIDNameMap,
                    collectionIDExportNameMap,
                    exportFolder,
                    incrementSuccess,
                    incrementFailed
                );
            }
            if (deletedExportedCollections?.length > 0) {
                addLogLine(
                    `removing ${deletedExportedCollections.length} collections`
                );
                await this.collectionRemover(
                    deletedExportedCollections,
                    exportFolder,
                    incrementSuccess,
                    incrementFailed
                );
            }
        } catch (e) {
            if (e.message !== CustomError.EXPORT_FOLDER_DOES_NOT_EXIST) {
                logError(e, 'runExport failed');
            }
            throw e;
        }
    }

    async collectionRenamer(
        exportFolder: string,
        collectionIDExportNameMap: Map<number, string>,
        renamedCollections: Collection[],
        incrementSuccess: () => void,
        incrementFailed: () => void
    ) {
        try {
            for (const collection of renamedCollections) {
                try {
                    this.verifyExportFolderExists(exportFolder);
                    const oldCollectionExportName =
                        collectionIDExportNameMap.get(collection.id);
                    const oldCollectionExportPath = getCollectionExportPath(
                        exportFolder,
                        oldCollectionExportName
                    );

                    const newCollectionExportName =
                        getUniqueCollectionExportName(
                            exportFolder,
                            collection.name
                        );
                    addLocalLog(
                        () =>
                            `renaming collection with id ${collection.id} from ${oldCollectionExportName} to ${newCollectionExportName}
                         `
                    );
                    const newCollectionExportPath = getCollectionExportPath(
                        exportFolder,
                        newCollectionExportName
                    );

                    await this.electronAPIs.rename(
                        oldCollectionExportPath,
                        newCollectionExportPath
                    );

                    await this.addCollectionExportedRecord(
                        exportFolder,
                        collection.id,
                        newCollectionExportName
                    );
                    collectionIDExportNameMap.set(
                        collection.id,
                        newCollectionExportName
                    );
                    incrementSuccess();
                } catch (e) {
                    incrementFailed();
                    logError(e, 'collectionRenamer failed a collection');
                    if (
                        e.message ===
                            CustomError.UPDATE_EXPORTED_RECORD_FAILED ||
                        e.message === CustomError.EXPORT_FOLDER_DOES_NOT_EXIST
                    ) {
                        throw e;
                    }
                }
            }
        } catch (e) {
            if (e.message !== CustomError.EXPORT_FOLDER_DOES_NOT_EXIST) {
                logError(e, 'collectionRenamer failed');
            }
            throw e;
        }
    }

    async collectionRemover(
        deletedExportedCollectionIDs: number[],
        exportFolder: string,
        incrementSuccess: () => void,
        incrementFailed: () => void
    ) {
        try {
            const exportRecord = await this.getExportRecord(exportFolder);
            const collectionIDPathMap =
                convertCollectionIDExportNameObjectToMap(
                    exportRecord.collectionExportNames
                );
            for (const collectionID of deletedExportedCollectionIDs) {
                try {
                    this.verifyExportFolderExists(exportFolder);
                    addLocalLog(
                        () =>
                            `removing collection with id ${collectionID} from export folder`
                    );
                    const collectionExportName =
                        collectionIDPathMap.get(collectionID);
                    // verify that the all exported files from the collection has been removed
                    const collectionExportedFiles = getCollectionExportedFiles(
                        exportRecord,
                        collectionID
                    );
                    if (collectionExportedFiles.length > 0) {
                        throw new Error(
                            "collection is not empty, can't remove"
                        );
                    }
                    const collectionExportPath = getCollectionExportPath(
                        exportFolder,
                        collectionExportName
                    );
                    // delete the collection metadata folder
                    await this.electronAPIs.deleteFolder(
                        getMetadataFolderExportPath(collectionExportPath)
                    );
                    // delete the collection folder
                    await this.electronAPIs.deleteFolder(collectionExportPath);
                    await this.removeCollectionExportedRecord(
                        exportFolder,
                        collectionID
                    );
                    incrementSuccess();
                } catch (e) {
                    incrementFailed();
                    logError(e, 'collectionRemover failed a collection');
                    if (
                        e.message ===
                            CustomError.UPDATE_EXPORTED_RECORD_FAILED ||
                        e.message === CustomError.EXPORT_FOLDER_DOES_NOT_EXIST
                    ) {
                        throw e;
                    }
                }
            }
        } catch (e) {
            if (e.message !== CustomError.EXPORT_FOLDER_DOES_NOT_EXIST) {
                logError(e, 'collectionRemover failed');
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
        incrementFailed: () => void
    ): Promise<void> {
        try {
            for (const file of files) {
                addLocalLog(
                    () =>
                        `exporting file ${file.metadata.title} with id ${
                            file.id
                        } from collection ${collectionIDNameMap.get(
                            file.collectionID
                        )}`
                );
                if (this.stopExport) {
                    break;
                }
                try {
                    this.verifyExportFolderExists(exportDir);
                    let collectionExportName = collectionIDFolderNameMap.get(
                        file.collectionID
                    );
                    if (!collectionExportName) {
                        collectionExportName =
                            await this.createNewCollectionExport(
                                exportDir,
                                file.collectionID,
                                collectionIDNameMap
                            );
                        await this.addCollectionExportedRecord(
                            exportDir,
                            file.collectionID,
                            collectionExportName
                        );
                        collectionIDFolderNameMap.set(
                            file.collectionID,
                            collectionExportName
                        );
                    }
                    const collectionExportPath = getCollectionExportPath(
                        exportDir,
                        collectionExportName
                    );
                    await this.electronAPIs.checkExistsAndCreateDir(
                        collectionExportPath
                    );
                    const fileExportName = await this.downloadAndSave(
                        collectionExportPath,
                        file
                    );
                    await this.addFileExportedRecord(
                        exportDir,
                        file,
                        fileExportName
                    );
                    incrementSuccess();
                } catch (e) {
                    incrementFailed();
                    logError(e, 'export failed for a file');
                    if (
                        e.message ===
                            CustomError.UPDATE_EXPORTED_RECORD_FAILED ||
                        e.message === CustomError.EXPORT_FOLDER_DOES_NOT_EXIST
                    ) {
                        throw e;
                    }
                }
            }
        } catch (e) {
            if (e.message !== CustomError.EXPORT_FOLDER_DOES_NOT_EXIST) {
                logError(e, 'fileExporter failed');
            }
            throw e;
        }
    }

    async fileTrasher(
        exportDir: string,
        collectionIDExportNameMap: Map<number, string>,
        removedFileUIDs: string[],
        incrementSuccess: () => void,
        incrementFailed: () => void
    ): Promise<void> {
        try {
            const exportRecord = await this.getExportRecord(exportDir);
            const fileIDExportNameMap = convertFileIDExportNameObjectToMap(
                exportRecord.fileExportNames
            );
            for (const fileUID of removedFileUIDs) {
                this.verifyExportFolderExists(exportDir);
                addLocalLog(() => `trashing file with id ${fileUID}`);
                if (this.stopExport) {
                    break;
                }
                try {
                    const fileExportName = fileIDExportNameMap.get(fileUID);
                    const collectionID = getCollectionIDFromFileUID(fileUID);
                    const collectionExportPath = getCollectionExportPath(
                        exportDir,
                        collectionIDExportNameMap.get(collectionID)
                    );

                    if (isLivePhotoExportName(fileExportName)) {
                        const {
                            image: imageExportName,
                            video: videoExportName,
                        } = parseLivePhotoExportName(fileExportName);
                        const imageExportPath = getFileExportPath(
                            collectionExportPath,
                            imageExportName
                        );
                        addLocalLog(
                            () =>
                                `moving image file ${imageExportPath} to trash folder`
                        );
                        await this.electronAPIs.moveFile(
                            imageExportPath,
                            getTrashedFileExportPath(exportDir, imageExportPath)
                        );

                        const imageMetadataFileExportPath =
                            getMetadataFileExportPath(imageExportPath);

                        await this.electronAPIs.moveFile(
                            imageMetadataFileExportPath,
                            getTrashedFileExportPath(
                                exportDir,
                                imageMetadataFileExportPath
                            )
                        );

                        const videoExportPath = getFileExportPath(
                            collectionExportPath,
                            videoExportName
                        );
                        addLocalLog(
                            () =>
                                `moving video file ${videoExportPath} to trash folder`
                        );
                        await this.electronAPIs.moveFile(
                            videoExportPath,
                            getTrashedFileExportPath(exportDir, videoExportPath)
                        );
                        const videoMetadataFileExportPath =
                            getMetadataFileExportPath(videoExportPath);
                        await this.electronAPIs.moveFile(
                            videoMetadataFileExportPath,
                            getTrashedFileExportPath(
                                exportDir,
                                videoMetadataFileExportPath
                            )
                        );
                    } else {
                        const fileExportPath = getFileExportPath(
                            collectionExportPath,
                            fileExportName
                        );
                        const trashedFilePath = getTrashedFileExportPath(
                            exportDir,
                            fileExportPath
                        );
                        addLocalLog(
                            () =>
                                `moving file ${fileExportPath} to ${trashedFilePath} trash folder`
                        );
                        await this.electronAPIs.moveFile(
                            fileExportPath,
                            trashedFilePath
                        );
                        const metadataFileExportPath =
                            getMetadataFileExportPath(fileExportPath);
                        await this.electronAPIs.moveFile(
                            metadataFileExportPath,
                            getTrashedFileExportPath(
                                exportDir,
                                metadataFileExportPath
                            )
                        );
                    }
                    await this.removeFileExportedRecord(exportDir, fileUID);
                    incrementSuccess();
                } catch (e) {
                    incrementFailed();
                    logError(e, 'trashing failed for a file');
                    if (
                        e.message ===
                            CustomError.UPDATE_EXPORTED_RECORD_FAILED ||
                        e.message === CustomError.EXPORT_FOLDER_DOES_NOT_EXIST
                    ) {
                        throw e;
                    }
                }
            }
        } catch (e) {
            if (e.message !== CustomError.EXPORT_FOLDER_DOES_NOT_EXIST) {
                logError(e, 'fileTrasher failed');
            }
            throw e;
        }
    }

    async addFileExportedRecord(
        folder: string,
        file: EnteFile,
        fileExportName: string
    ) {
        try {
            const fileUID = getExportRecordFileUID(file);
            const exportRecord = await this.getExportRecord(folder);
            if (!exportRecord.fileExportNames) {
                exportRecord.fileExportNames = {};
            }
            exportRecord.fileExportNames = {
                ...exportRecord.fileExportNames,
                [fileUID]: fileExportName,
            };
            await this.updateExportRecord(exportRecord, folder);
        } catch (e) {
            if (e.message !== CustomError.EXPORT_FOLDER_DOES_NOT_EXIST) {
                logError(e, 'addFileExportedRecord failed');
            }
            throw e;
        }
    }

    async addCollectionExportedRecord(
        folder: string,
        collectionID: number,
        collectionExportName: string
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

            await this.updateExportRecord(exportRecord, folder);
        } catch (e) {
            if (e.message !== CustomError.EXPORT_FOLDER_DOES_NOT_EXIST) {
                logError(e, 'addCollectionExportedRecord failed');
            }
            throw e;
        }
    }

    async removeCollectionExportedRecord(folder: string, collectionID: number) {
        try {
            const exportRecord = await this.getExportRecord(folder);

            exportRecord.collectionExportNames = Object.fromEntries(
                Object.entries(exportRecord.collectionExportNames).filter(
                    ([key]) => key !== collectionID.toString()
                )
            );

            await this.updateExportRecord(exportRecord, folder);
        } catch (e) {
            if (e.message !== CustomError.EXPORT_FOLDER_DOES_NOT_EXIST) {
                logError(e, 'removeCollectionExportedRecord failed');
            }
            throw e;
        }
    }

    async removeFileExportedRecord(folder: string, fileUID: string) {
        try {
            const exportRecord = await this.getExportRecord(folder);
            exportRecord.fileExportNames = Object.fromEntries(
                Object.entries(exportRecord.fileExportNames).filter(
                    ([key]) => key !== fileUID
                )
            );
            await this.updateExportRecord(exportRecord, folder);
        } catch (e) {
            if (e.message !== CustomError.EXPORT_FOLDER_DOES_NOT_EXIST) {
                logError(e, 'removeFileExportedRecord failed');
            }
            throw e;
        }
    }

    async updateExportRecord(newData: Partial<ExportRecord>, folder: string) {
        const response = this.exportRecordUpdater.queueUpRequest(() =>
            this.updateExportRecordHelper(folder, newData)
        );
        return response.promise;
    }

    async updateExportRecordHelper(
        folder: string,
        newData: Partial<ExportRecord>
    ) {
        try {
            const exportRecord = await this.getExportRecord(folder);
            const newRecord: ExportRecord = { ...exportRecord, ...newData };
            await this.electronAPIs.saveFileToDisk(
                `${folder}/${EXPORT_RECORD_FILE_NAME}`,
                JSON.stringify(newRecord, null, 2)
            );
            return newRecord;
        } catch (e) {
            if (e.message === CustomError.EXPORT_FOLDER_DOES_NOT_EXIST) {
                throw e;
            }
            logError(e, 'error updating Export Record');
            throw Error(CustomError.UPDATE_EXPORTED_RECORD_FAILED);
        }
    }

    async getExportRecord(folder: string): Promise<ExportRecord> {
        try {
            this.verifyExportFolderExists(folder);
            const exportRecordJSONPath = `${folder}/${EXPORT_RECORD_FILE_NAME}`;
            if (!this.exists(exportRecordJSONPath)) {
                return this.createEmptyExportRecord(exportRecordJSONPath);
            }
            const recordFile = await this.electronAPIs.readTextFile(
                exportRecordJSONPath
            );
            return JSON.parse(recordFile);
        } catch (e) {
            if (e.message !== CustomError.EXPORT_FOLDER_DOES_NOT_EXIST) {
                logError(e, 'export Record JSON parsing failed');
            }
            throw e;
        }
    }

    async createNewCollectionExport(
        exportFolder: string,
        collectionID: number,
        collectionIDNameMap: Map<number, string>
    ) {
        this.verifyExportFolderExists(exportFolder);
        const collectionName = collectionIDNameMap.get(collectionID);
        const collectionExportName = getUniqueCollectionExportName(
            exportFolder,
            collectionName
        );
        const collectionExportPath = getCollectionExportPath(
            exportFolder,
            collectionExportName
        );
        await this.electronAPIs.checkExistsAndCreateDir(collectionExportPath);
        await this.electronAPIs.checkExistsAndCreateDir(
            getMetadataFolderExportPath(collectionExportPath)
        );

        return collectionExportName;
    }

    async downloadAndSave(
        collectionExportPath: string,
        file: EnteFile
    ): Promise<string> {
        try {
            const fileExportName = getUniqueFileExportName(
                collectionExportPath,
                file.metadata.title
            );
            let fileStream = await retryAsyncFunction(() =>
                downloadManager.downloadFile(file)
            );
            const fileType = getFileExtension(file.metadata.title);
            if (
                file.pubMagicMetadata?.data.editedTime &&
                (fileType === TYPE_JPEG || fileType === TYPE_JPG)
            ) {
                const fileBlob = await new Response(fileStream).blob();
                if (!this.fileReader) {
                    this.fileReader = new FileReader();
                }
                const updatedFileBlob = await updateFileCreationDateInEXIF(
                    this.fileReader,
                    fileBlob,
                    new Date(file.pubMagicMetadata.data.editedTime / 1000)
                );
                fileStream = updatedFileBlob.stream();
            }
            if (file.metadata.fileType === FILE_TYPE.LIVE_PHOTO) {
                return await this.exportLivePhoto(
                    collectionExportPath,
                    fileStream,
                    file
                );
            } else {
                await this.saveMediaFile(
                    collectionExportPath,
                    fileExportName,
                    fileStream
                );
                await this.saveMetadataFile(
                    collectionExportPath,
                    fileExportName,
                    file
                );
                return fileExportName;
            }
        } catch (e) {
            logError(e, 'download and save failed');
            throw e;
        }
    }

    private async exportLivePhoto(
        collectionExportPath: string,
        fileStream: ReadableStream<any>,
        file: EnteFile
    ) {
        const fileBlob = await new Response(fileStream).blob();
        const livePhoto = await decodeLivePhoto(file, fileBlob);
        const imageStream = generateStreamFromArrayBuffer(livePhoto.image);
        const imageExportName = getUniqueFileExportName(
            collectionExportPath,
            livePhoto.imageNameTitle
        );
        await this.saveMediaFile(
            collectionExportPath,
            imageExportName,
            imageStream
        );
        await this.saveMetadataFile(
            collectionExportPath,
            imageExportName,
            file
        );

        const videoStream = generateStreamFromArrayBuffer(livePhoto.video);
        const videoExportName = getUniqueFileExportName(
            collectionExportPath,
            livePhoto.videoNameTitle
        );
        await this.saveMediaFile(
            collectionExportPath,
            videoExportName,
            videoStream
        );
        await this.saveMetadataFile(
            collectionExportPath,
            videoExportName,
            file
        );

        return getLivePhotoExportName(imageExportName, videoExportName);
    }

    private async saveMediaFile(
        collectionExportPath: string,
        fileExportName: string,
        fileStream: ReadableStream<any>
    ) {
        await this.electronAPIs.saveStreamToDisk(
            getFileExportPath(collectionExportPath, fileExportName),
            fileStream
        );
    }
    private async saveMetadataFile(
        collectionExportPath: string,
        fileExportName: string,
        file: EnteFile
    ) {
        await this.electronAPIs.saveFileToDisk(
            getFileMetadataExportPath(collectionExportPath, fileExportName),
            getGoogleLikeMetadataFile(fileExportName, file)
        );
    }

    isExportInProgress = () => {
        return this.exportInProgress;
    };

    exists = (path: string) => {
        return this.electronAPIs.exists(path);
    };

    rename = (oldPath: string, newPath: string) => {
        return this.electronAPIs.rename(oldPath, newPath);
    };

    checkExistsAndCreateDir = (path: string) => {
        return this.electronAPIs.checkExistsAndCreateDir(path);
    };

    exportFolderExists = (exportFolder: string) => {
        return exportFolder && this.exists(exportFolder);
    };

    private verifyExportFolderExists = (exportFolder: string) => {
        try {
            if (!this.exportFolderExists(exportFolder)) {
                throw Error(CustomError.EXPORT_FOLDER_DOES_NOT_EXIST);
            }
        } catch (e) {
            if (e.message !== CustomError.EXPORT_FOLDER_DOES_NOT_EXIST) {
                logError(e, 'verifyExportFolderExists failed');
            }
            throw e;
        }
    };

    private createEmptyExportRecord = async (exportRecordJSONPath: string) => {
        const exportRecord: ExportRecord = NULL_EXPORT_RECORD;
        await this.electronAPIs.saveFileToDisk(
            exportRecordJSONPath,
            JSON.stringify(exportRecord, null, 2)
        );
        return exportRecord;
    };
}
export default new ExportService();
