import { sleep } from 'utils/common';
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
import { logError } from '@ente/shared/sentry';
import { getData, LS_KEYS, setData } from '@ente/shared/storage/localStorage';
import { getAllLocalCollections } from '../collectionService';
import downloadManager from '../download';
import { getAllLocalFiles } from '../fileService';
import { EnteFile } from 'types/file';

import { decodeLivePhoto } from '../livePhotoService';
import {
    generateStreamFromArrayBuffer,
    getPersonalFiles,
    getUpdatedEXIFFileForDownload,
    mergeMetadata,
} from 'utils/file';

import QueueProcessor, {
    CancellationStatus,
    RequestCanceller,
} from '../queueProcessor';
import { Collection } from 'types/collection';
import {
    ExportProgress,
    ExportRecord,
    ExportSettings,
    ExportUIUpdaters,
} from 'types/export';
import { User } from '@ente/shared/user/types';
import { FILE_TYPE } from 'constants/file';
import { ExportStage } from 'constants/export';
import { CustomError } from '@ente/shared/error';
import { addLogLine } from '@ente/shared/logging';
import { eventBus, Events } from '@ente/shared/events';
import {
    constructCollectionNameMap,
    getCollectionUserFacingName,
    getNonEmptyPersonalCollections,
} from 'utils/collection';
import { migrateExport } from './migration';
import ElectronAPIs from '@ente/shared/electron';

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
    private exportSettings: ExportSettings;
    private exportInProgress: RequestCanceller = null;
    private reRunNeeded = false;
    private exportRecordUpdater = new QueueProcessor<ExportRecord>(1);
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

    async runMigration(
        exportDir: string,
        exportRecord: ExportRecord,
        updateProgress: (progress: ExportProgress) => void
    ) {
        try {
            addLogLine('running migration');
            await migrateExport(exportDir, exportRecord, updateProgress);
            addLogLine('migration completed');
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
            const newRootDir = await ElectronAPIs.selectDirectory();
            if (!newRootDir) {
                throw Error(CustomError.SELECT_FOLDER_ABORTED);
            }
            const newExportDir = `${newRootDir}/${ENTE_EXPORT_DIRECTORY}`;
            await ElectronAPIs.checkExistsAndCreateDir(newExportDir);
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
            await ElectronAPIs.openDirectory(exportFolder);
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

    getPendingExports = async (
        exportRecord: ExportRecord
    ): Promise<EnteFile[]> => {
        try {
            const user: User = getData(LS_KEYS.USER);
            const files = await getAllLocalFiles();
            const collections = await getAllLocalCollections();
            const collectionIdToOwnerIDMap = new Map<number, number>(
                collections.map((collection) => [
                    collection.id,
                    collection.owner.id,
                ])
            );
            const userPersonalFiles = getPersonalFiles(
                files,
                user,
                collectionIdToOwnerIDMap
            );

            const unExportedFiles = getUnExportedFiles(
                userPersonalFiles,
                exportRecord
            );
            return unExportedFiles;
        } catch (e) {
            logError(e, 'getUpdateFileLists failed');
            throw e;
        }
    };

    async preExport(exportFolder: string) {
        this.verifyExportFolderExists(exportFolder);
        const exportRecord = await this.getExportRecord(exportFolder);
        await this.updateExportStage(ExportStage.MIGRATION);
        await this.runMigration(
            exportFolder,
            exportRecord,
            this.updateExportProgress.bind(this)
        );
        await this.updateExportStage(ExportStage.STARTING);
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

            const pendingExports = await this.getPendingExports(exportRecord);
            this.uiUpdater.setPendingExports(pendingExports);
        } catch (e) {
            logError(e, 'postExport failed');
        }
    }

    async stopRunningExport() {
        try {
            addLogLine('user requested export cancellation');
            this.exportInProgress.exec();
            this.exportInProgress = null;
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
                addLogLine('export started');
                await this.runExport(exportFolder, isCanceled);
                addLogLine('export completed');
            } finally {
                if (isCanceled.status) {
                    addLogLine('export cancellation done');
                    if (!this.exportInProgress) {
                        await this.postExport();
                    }
                } else {
                    await this.postExport();
                    addLogLine('resetting export in progress after completion');
                    this.exportInProgress = null;
                    if (this.reRunNeeded) {
                        this.reRunNeeded = false;
                        addLogLine('re-running export');
                        setTimeout(() => this.scheduleExport(), 0);
                    }
                }
            }
        } catch (e) {
            if (
                e.message !== CustomError.EXPORT_FOLDER_DOES_NOT_EXIST &&
                e.message !== CustomError.EXPORT_STOPPED
            ) {
                logError(e, 'scheduleExport failed');
            }
        }
    };

    private async runExport(
        exportFolder: string,
        isCanceled: CancellationStatus
    ) {
        try {
            const user: User = getData(LS_KEYS.USER);
            const files = mergeMetadata(await getAllLocalFiles());
            const collections = await getAllLocalCollections();
            const collectionIdToOwnerIDMap = new Map<number, number>(
                collections.map((collection) => [
                    collection.id,
                    collection.owner.id,
                ])
            );
            const personalFiles = getPersonalFiles(
                files,
                user,
                collectionIdToOwnerIDMap
            );

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
            const collectionIDNameMap = constructCollectionNameMap(
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

            addLogLine(
                `personal files:${personalFiles.length} unexported files: ${filesToExport.length}, deleted exported files: ${removedFileUIDs.length}, renamed collections: ${renamedCollections.length}, deleted collections: ${deletedExportedCollections.length}`
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
                addLogLine(`renaming ${renamedCollections.length} collections`);
                await this.collectionRenamer(
                    exportFolder,
                    collectionIDExportNameMap,
                    renamedCollections,
                    isCanceled
                );
            }

            if (removedFileUIDs?.length > 0) {
                this.updateExportStage(ExportStage.TRASHING_DELETED_FILES);
                addLogLine(`trashing ${removedFileUIDs.length} files`);
                await this.fileTrasher(
                    exportFolder,
                    collectionIDExportNameMap,
                    removedFileUIDs,
                    isCanceled
                );
            }
            if (filesToExport?.length > 0) {
                this.updateExportStage(ExportStage.EXPORTING_FILES);
                addLogLine(`exporting ${filesToExport.length} files`);
                await this.fileExporter(
                    filesToExport,
                    collectionIDNameMap,
                    collectionIDExportNameMap,
                    exportFolder,
                    incrementSuccess,
                    incrementFailed,
                    isCanceled
                );
            }
            if (deletedExportedCollections?.length > 0) {
                this.updateExportStage(
                    ExportStage.TRASHING_DELETED_COLLECTIONS
                );
                addLogLine(
                    `removing ${deletedExportedCollections.length} collections`
                );
                await this.collectionRemover(
                    deletedExportedCollections,
                    exportFolder,
                    isCanceled
                );
            }
        } catch (e) {
            if (
                e.message !== CustomError.EXPORT_FOLDER_DOES_NOT_EXIST &&
                e.message !== CustomError.EXPORT_STOPPED
            ) {
                logError(e, 'runExport failed');
            }
            throw e;
        }
    }

    async collectionRenamer(
        exportFolder: string,
        collectionIDExportNameMap: Map<number, string>,
        renamedCollections: Collection[],
        isCanceled: CancellationStatus
    ) {
        try {
            for (const collection of renamedCollections) {
                try {
                    if (isCanceled.status) {
                        throw Error(CustomError.EXPORT_STOPPED);
                    }
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
                            getCollectionUserFacingName(collection)
                        );
                    addLogLine(
                        `renaming collection with id ${collection.id} from ${oldCollectionExportName} to ${newCollectionExportName}`
                    );
                    const newCollectionExportPath = getCollectionExportPath(
                        exportFolder,
                        newCollectionExportName
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
                    try {
                        await ElectronAPIs.rename(
                            oldCollectionExportPath,
                            newCollectionExportPath
                        );
                    } catch (e) {
                        await this.addCollectionExportedRecord(
                            exportFolder,
                            collection.id,
                            oldCollectionExportName
                        );
                        collectionIDExportNameMap.set(
                            collection.id,
                            oldCollectionExportName
                        );
                        throw e;
                    }
                    addLogLine(
                        `renaming collection with id ${collection.id} from ${oldCollectionExportName} to ${newCollectionExportName} successful`
                    );
                } catch (e) {
                    logError(e, 'collectionRenamer failed a collection');
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
                logError(e, 'collectionRenamer failed');
            }
            throw e;
        }
    }

    async collectionRemover(
        deletedExportedCollectionIDs: number[],
        exportFolder: string,
        isCanceled: CancellationStatus
    ) {
        try {
            const exportRecord = await this.getExportRecord(exportFolder);
            const collectionIDPathMap =
                convertCollectionIDExportNameObjectToMap(
                    exportRecord.collectionExportNames
                );
            for (const collectionID of deletedExportedCollectionIDs) {
                try {
                    if (isCanceled.status) {
                        throw Error(CustomError.EXPORT_STOPPED);
                    }
                    this.verifyExportFolderExists(exportFolder);
                    addLogLine(
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
                    await this.removeCollectionExportedRecord(
                        exportFolder,
                        collectionID
                    );
                    try {
                        // delete the collection metadata folder
                        await ElectronAPIs.deleteFolder(
                            getMetadataFolderExportPath(collectionExportPath)
                        );
                        // delete the collection folder
                        await ElectronAPIs.deleteFolder(collectionExportPath);
                    } catch (e) {
                        await this.addCollectionExportedRecord(
                            exportFolder,
                            collectionID,
                            collectionExportName
                        );
                        throw e;
                    }
                    addLogLine(
                        `removing collection with id ${collectionID} from export folder successful`
                    );
                } catch (e) {
                    logError(e, 'collectionRemover failed a collection');
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
        incrementFailed: () => void,
        isCanceled: CancellationStatus
    ): Promise<void> {
        try {
            for (const file of files) {
                addLogLine(
                    `exporting file ${file.metadata.title} with id ${
                        file.id
                    } from collection ${collectionIDNameMap.get(
                        file.collectionID
                    )}`
                );
                if (isCanceled.status) {
                    throw Error(CustomError.EXPORT_STOPPED);
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
                    await ElectronAPIs.checkExistsAndCreateDir(
                        collectionExportPath
                    );
                    await ElectronAPIs.checkExistsAndCreateDir(
                        getMetadataFolderExportPath(collectionExportPath)
                    );
                    await this.downloadAndSave(
                        exportDir,
                        collectionExportPath,
                        file
                    );
                    incrementSuccess();
                    addLogLine(
                        `exporting file ${file.metadata.title} with id ${
                            file.id
                        } from collection ${collectionIDNameMap.get(
                            file.collectionID
                        )} successful`
                    );
                } catch (e) {
                    incrementFailed();
                    logError(e, 'export failed for a file');
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
                logError(e, 'fileExporter failed');
            }
            throw e;
        }
    }

    async fileTrasher(
        exportDir: string,
        collectionIDExportNameMap: Map<number, string>,
        removedFileUIDs: string[],
        isCanceled: CancellationStatus
    ): Promise<void> {
        try {
            const exportRecord = await this.getExportRecord(exportDir);
            const fileIDExportNameMap = convertFileIDExportNameObjectToMap(
                exportRecord.fileExportNames
            );
            for (const fileUID of removedFileUIDs) {
                this.verifyExportFolderExists(exportDir);
                addLogLine(`trashing file with id ${fileUID}`);
                if (isCanceled.status) {
                    throw Error(CustomError.EXPORT_STOPPED);
                }
                try {
                    const fileExportName = fileIDExportNameMap.get(fileUID);
                    const collectionID = getCollectionIDFromFileUID(fileUID);
                    const collectionExportPath = getCollectionExportPath(
                        exportDir,
                        collectionIDExportNameMap.get(collectionID)
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
                                imageExportName
                            );
                            addLogLine(
                                `moving image file ${imageExportPath} to trash folder`
                            );
                            if (this.exists(imageExportPath)) {
                                await ElectronAPIs.moveFile(
                                    imageExportPath,
                                    getTrashedFileExportPath(
                                        exportDir,
                                        imageExportPath
                                    )
                                );
                            }

                            const imageMetadataFileExportPath =
                                getMetadataFileExportPath(imageExportPath);

                            if (this.exists(imageMetadataFileExportPath)) {
                                await ElectronAPIs.moveFile(
                                    imageMetadataFileExportPath,
                                    getTrashedFileExportPath(
                                        exportDir,
                                        imageMetadataFileExportPath
                                    )
                                );
                            }

                            const videoExportPath = getFileExportPath(
                                collectionExportPath,
                                videoExportName
                            );
                            addLogLine(
                                `moving video file ${videoExportPath} to trash folder`
                            );
                            if (this.exists(videoExportPath)) {
                                await ElectronAPIs.moveFile(
                                    videoExportPath,
                                    getTrashedFileExportPath(
                                        exportDir,
                                        videoExportPath
                                    )
                                );
                            }
                            const videoMetadataFileExportPath =
                                getMetadataFileExportPath(videoExportPath);
                            if (this.exists(videoMetadataFileExportPath)) {
                                await ElectronAPIs.moveFile(
                                    videoMetadataFileExportPath,
                                    getTrashedFileExportPath(
                                        exportDir,
                                        videoMetadataFileExportPath
                                    )
                                );
                            }
                        } else {
                            const fileExportPath = getFileExportPath(
                                collectionExportPath,
                                fileExportName
                            );
                            const trashedFilePath = getTrashedFileExportPath(
                                exportDir,
                                fileExportPath
                            );
                            addLogLine(
                                `moving file ${fileExportPath} to ${trashedFilePath} trash folder`
                            );
                            if (this.exists(fileExportPath)) {
                                await ElectronAPIs.moveFile(
                                    fileExportPath,
                                    trashedFilePath
                                );
                            }
                            const metadataFileExportPath =
                                getMetadataFileExportPath(fileExportPath);
                            if (this.exists(metadataFileExportPath)) {
                                await ElectronAPIs.moveFile(
                                    metadataFileExportPath,
                                    getTrashedFileExportPath(
                                        exportDir,
                                        metadataFileExportPath
                                    )
                                );
                            }
                        }
                    } catch (e) {
                        await this.addFileExportedRecord(
                            exportDir,
                            fileUID,
                            fileExportName
                        );
                        throw e;
                    }
                    addLogLine(`trashing file with id ${fileUID} successful`);
                } catch (e) {
                    logError(e, 'trashing failed for a file');
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
                logError(e, 'fileTrasher failed');
            }
            throw e;
        }
    }

    async addFileExportedRecord(
        folder: string,
        fileUID: string,
        fileExportName: string
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

            await this.updateExportRecord(folder, exportRecord);
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

            await this.updateExportRecord(folder, exportRecord);
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
            await this.updateExportRecord(folder, exportRecord);
        } catch (e) {
            if (e.message !== CustomError.EXPORT_FOLDER_DOES_NOT_EXIST) {
                logError(e, 'removeFileExportedRecord failed');
            }
            throw e;
        }
    }

    async updateExportRecord(folder: string, newData: Partial<ExportRecord>) {
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
            await ElectronAPIs.saveFileToDisk(
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

    async getExportRecord(folder: string, retry = true): Promise<ExportRecord> {
        try {
            this.verifyExportFolderExists(folder);
            const exportRecordJSONPath = `${folder}/${EXPORT_RECORD_FILE_NAME}`;
            if (!this.exists(exportRecordJSONPath)) {
                return this.createEmptyExportRecord(exportRecordJSONPath);
            }
            const recordFile = await ElectronAPIs.readTextFile(
                exportRecordJSONPath
            );
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
        await ElectronAPIs.checkExistsAndCreateDir(collectionExportPath);
        await ElectronAPIs.checkExistsAndCreateDir(
            getMetadataFolderExportPath(collectionExportPath)
        );

        return collectionExportName;
    }

    async downloadAndSave(
        exportDir: string,
        collectionExportPath: string,
        file: EnteFile
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
                originalFileStream
            );
            if (file.metadata.fileType === FILE_TYPE.LIVE_PHOTO) {
                await this.exportLivePhoto(
                    exportDir,
                    fileUID,
                    collectionExportPath,
                    updatedFileStream,
                    file
                );
            } else {
                const fileExportName = getUniqueFileExportName(
                    collectionExportPath,
                    file.metadata.title
                );
                await this.addFileExportedRecord(
                    exportDir,
                    fileUID,
                    fileExportName
                );
                try {
                    await this.saveMetadataFile(
                        collectionExportPath,
                        fileExportName,
                        file
                    );
                    await ElectronAPIs.saveStreamToDisk(
                        getFileExportPath(collectionExportPath, fileExportName),
                        updatedFileStream
                    );
                } catch (e) {
                    await this.removeFileExportedRecord(exportDir, fileUID);
                    throw e;
                }
            }
        } catch (e) {
            logError(e, 'download and save failed');
            throw e;
        }
    }

    private async exportLivePhoto(
        exportDir: string,
        fileUID: string,
        collectionExportPath: string,
        fileStream: ReadableStream<any>,
        file: EnteFile
    ) {
        const fileBlob = await new Response(fileStream).blob();
        const livePhoto = await decodeLivePhoto(file, fileBlob);
        const imageExportName = getUniqueFileExportName(
            collectionExportPath,
            livePhoto.imageNameTitle
        );
        const videoExportName = getUniqueFileExportName(
            collectionExportPath,
            livePhoto.videoNameTitle
        );
        const livePhotoExportName = getLivePhotoExportName(
            imageExportName,
            videoExportName
        );
        await this.addFileExportedRecord(
            exportDir,
            fileUID,
            livePhotoExportName
        );
        try {
            const imageStream = generateStreamFromArrayBuffer(livePhoto.image);
            await this.saveMetadataFile(
                collectionExportPath,
                imageExportName,
                file
            );
            await ElectronAPIs.saveStreamToDisk(
                getFileExportPath(collectionExportPath, imageExportName),
                imageStream
            );

            const videoStream = generateStreamFromArrayBuffer(livePhoto.video);
            await this.saveMetadataFile(
                collectionExportPath,
                videoExportName,
                file
            );
            try {
                await ElectronAPIs.saveStreamToDisk(
                    getFileExportPath(collectionExportPath, videoExportName),
                    videoStream
                );
            } catch (e) {
                ElectronAPIs.deleteFile(
                    getFileExportPath(collectionExportPath, imageExportName)
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
        file: EnteFile
    ) {
        await ElectronAPIs.saveFileToDisk(
            getFileMetadataExportPath(collectionExportPath, fileExportName),
            getGoogleLikeMetadataFile(fileExportName, file)
        );
    }

    isExportInProgress = () => {
        return this.exportInProgress;
    };

    exists = (path: string) => {
        return ElectronAPIs.exists(path);
    };

    rename = (oldPath: string, newPath: string) => {
        return ElectronAPIs.rename(oldPath, newPath);
    };

    checkExistsAndCreateDir = (path: string) => {
        return ElectronAPIs.checkExistsAndCreateDir(path);
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
        await ElectronAPIs.saveFileToDisk(
            exportRecordJSONPath,
            JSON.stringify(exportRecord, null, 2)
        );
        return exportRecord;
    };
}
export default new ExportService();
